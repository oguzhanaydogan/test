terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.59.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "DefaultResourceGroup-EUS"
    storage_account_name = "ccseyhan2"
    container_name       = "terraformstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features{}
}
##RG##
module "resourcegroup" {
  source = "./modules/ResourceGroup"
  location = "East US"
  name = "DemoResourceGroup"
}
##VNET##
module "virtualnetwork" {
  source = "./modules/VirtualNetwork"
  name = "example-network"
  location = module.resourcegroup.location
  resource_group_name = module.resourcegroup.name
  address_space = ["10.0.0.0/16"]
}

module "subnets" {
  source = "./modules/subnet"
  for_each = var.subnets
  resource_group_name = module.resourcegroup.name
  virtual_network_name = module.virtualnetwork.name
  subnet_name = each.key
  address_prefixes = each.value.address_prefixes
  delegation = each.value.delegation
}

resource "azurerm_service_plan" "example" {
  name                = "oaydoganwebapp"
  resource_group_name = module.resourcegroup.name
  location            = module.resourcegroup.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

data "azurerm_key_vault" "example" {
  name                = "coykeyvault"
  resource_group_name = module.resourcegroup.name
}
data "azurerm_key_vault_secret" "db_password" {
  name         = "MYSQLPASSWORD"
  key_vault_id = data.azurerm_key_vault.example.id
  depends_on = [ azurerm_key_vault_access_policy.kvaccess ]
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_access_policy" "kvaccess" {
  key_vault_id = data.azurerm_key_vault.example.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List",
  ]
  secret_permissions = [
    "Get", "List",
  ]
}

data "azurerm_role_definition" "acrpull" {
  name = "AcrPull"
}

resource "azurerm_role_assignment" "web1_role_assignment" {
  scope              = module.ACR.id
  role_definition_id = data.azurerm_role_definition.acrpull.id
  principal_id       = module.webapp1.key_vault_reference_identity_id
}
module "webapp1" {
  source = "./modules/webapp"
  name = "coywebapp1"
  resource_group_name = module.resourcegroup.name
  location = module.resourcegroup.location
  service_plan_id = azurerm_service_plan.example.id
  image_name = "coyhub.azurecr.io/web-server"
  image_tag = "latest"
  
  app_settings = {
    "MYSQL_PASSWORD"=data.azurerm_key_vault_secret.db_password.value
    "MYSQL_DATABASE_HOST"=module.mysql.host
    "MYSQL_DATABASE"=module.mysql.database_name
    "MYSQL_USER"="${module.mysql.database_username}@${module.mysql.host}"
    "APPINSIGHTS_INSTRUMENTATIONKEY"=azurerm_application_insights.insight.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"=azurerm_application_insights.insight.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION"="~3"
    }
}

resource "azurerm_role_assignment" "web2_role_assignment" {
  scope              = module.ACR.id
  principal_id       = module.webapp2.key_vault_reference_identity_id
  role_definition_name = "AcrPull"
}
module "webapp2" {
  source = "./modules/webapp"
  name = "coywebapp2"
  resource_group_name = module.resourcegroup.name
  location = module.resourcegroup.location
  service_plan_id = azurerm_service_plan.example.id
  image_name = "coyhub.azurecr.io/result-server"
  image_tag = "latest"
    app_settings = {
    "MYSQL_PASSWORD"=data.azurerm_key_vault_secret.db_password.value
    "MYSQL_DATABASE_HOST"=module.mysql.host
    "MYSQL_DATABASE"=module.mysql.database_name
    "MYSQL_USER"=module.mysql.database_username    
    }
  }

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration1" {
  app_service_id = module.webapp1.id
  subnet_id      = module.subnets["app-subnet"].id
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration2" {
  app_service_id = module.webapp2.id
  subnet_id      = module.subnets["app-subnet"].id
}

module "ACR" {
  source = "./modules/AzureContainerRegistry"
  name = "coyhub"
  resource_group_name = module.resourcegroup.name
  location = module.resourcegroup.location
}

module "private_dns_zone_acr" {
  source = "./modules/privatednszone"
  name = "privatelink.azurecr.io"
  resourcegroup = module.resourcegroup.name
  virtual_network_id = module.virtualnetwork.id
  attached_resource_name = module.ACR.name
}

module "private_endpoint_acr" {
    source = "./modules/privateendpoint"
    resourcegroup = module.resourcegroup.name
    location = module.resourcegroup.location
    subnet_id = module.subnets["acr_subnet"].id
    private_dns_zone_ids = ["${module.private_dns_zone_acr.id}"]
    attached_resource_name = module.ACR.name
    attached_resource_id = module.ACR.id
    subresource_name = "registry"
}

module "private_dns_zone_apps" {
  source = "./modules/privatednszone"
  name = "privatelink.azurewebsites.net"
  resourcegroup = module.resourcegroup.name
  virtual_network_id = module.virtualnetwork.id
  attached_resource_name = "apps"
}

module "private_endpoint_app1" {
    source = "./modules/privateendpoint"
    resourcegroup = module.resourcegroup.name
    location = module.resourcegroup.location
    subnet_id = module.subnets["app1endpoint_subnet"].id
    private_dns_zone_ids = ["${module.private_dns_zone_apps.id}"]
    attached_resource_name = module.webapp1.name
    attached_resource_id = module.webapp1.id
    subresource_name = "sites"
}

module "private_endpoint_app2" {
    source = "./modules/privateendpoint"
    resourcegroup = module.resourcegroup.name
    location = module.resourcegroup.location
    subnet_id = module.subnets["app2endpoint_subnet"].id
    private_dns_zone_ids = ["${module.private_dns_zone_apps.id}"]
    attached_resource_name = module.webapp2.name
    attached_resource_id = module.webapp2.id
    subresource_name = "sites"
}
module "mysql" {
  source = "./modules/MySql"
  server_name = "coy-database-server"
  location = module.resourcegroup.location
  resourcegroup = module.resourcegroup.name
  db_name = "phonebook"
  admin_username = "coyadmin"
  admin_password = data.azurerm_key_vault_secret.db_password.value
  delegated_subnet_id = module.subnets["mysql_subnet"].id
  private_dns_zone_id = module.private_dns_zone_mysql.id
}

module "private_dns_zone_mysql" {
  source = "./modules/privatednszone"
  name = "privatelink.mysql.database.azure.com"
  resourcegroup = module.resourcegroup.name
  attached_resource_name = module.mysql.name
  virtual_network_id = module.virtualnetwork.id
}
resource "azurerm_virtual_machine" "vm1" {
  name                  = var.vm_name
  location              = module.resourcegroup.location
  resource_group_name   = module.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_D2s_v3"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.vm_name
    admin_username = var.admin_username
    custom_data = file("userdata.sh")
    
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = data.azurerm_ssh_public_key.ssh_public_key.public_key
   }
 }
}

resource "azurerm_public_ip" "pip1" {
  name                = "${var.vm_name}-pip"
  resource_group_name = module.resourcegroup.name
  location            = module.resourcegroup.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.vm_name}-nic"
  location            = module.resourcegroup.location
  resource_group_name = module.resourcegroup.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = module.subnets["acr_subnet"].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip1.id
  }
}


data "azurerm_ssh_public_key" "ssh_public_key" {
  resource_group_name = var.ssh_key_rg
  name                = var.ssh_key_name
}


resource "azurerm_network_interface_security_group_association" "nic1" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

resource "azurerm_network_security_group" "nsg1" {
    name                = "nsgwithsshopen"
    location            = module.resourcegroup.location
    resource_group_name = module.resourcegroup.name

    security_rule {
        name                       = "AllowSSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

data "azurerm_subscription" "current" {}

data "azurerm_role_definition" "acrpush" {
  name = "AcrPush"
}

resource "azurerm_role_assignment" "example" {
  scope              = module.ACR.id
  role_definition_id = data.azurerm_role_definition.acrpush.id
  principal_id       = azurerm_virtual_machine.vm1.identity[0].principal_id
}

resource "azurerm_application_insights" "insight" {
  name                = "tf-test-appinsights"
  location            = module.resourcegroup.location
  resource_group_name = module.resourcegroup.name
  application_type    = "web"
}

#test
# resource "azurerm_public_ip" "appgw_pip" {
#   name                = "appgw-pip"
#   resource_group_name = module.resourcegroup.name
#   location            = module.resourcegroup.location
#   allocation_method   = "Dynamic"
# }

# # since these variables are re-used - a locals block makes this more maintainable
# locals {
#   backend_address_pool_name      = "${azurerm_virtual_network.example.name}-beap"
#   frontend_port_name             = "${azurerm_virtual_network.example.name}-feport"
#   frontend_ip_configuration_name = "${azurerm_virtual_network.example.name}-feip"
#   http_setting_name              = "${azurerm_virtual_network.example.name}-be-htst"
#   listener_name                  = "${azurerm_virtual_network.example.name}-httplstn"
#   request_routing_rule_name      = "${azurerm_virtual_network.example.name}-rqrt"
#   redirect_configuration_name    = "${azurerm_virtual_network.example.name}-rdrcfg"
# }

# resource "azurerm_application_gateway" "appgw" {
#   name                = "coy-appgateway"
#   resource_group_name = module.resourcegroup.name
#   location            = module.resourcegroup.location

#   sku {
#     name     = "Standard_Small"
#     tier     = "Standard"
#     capacity = 2
#   }

#   gateway_ip_configuration {
#     name      = "my-gateway-ip-configuration"
#     subnet_id = module.subnets["appgateway_subnet"]
#   }

#   frontend_port {
#     name = local.frontend_port_name
#     port = 443
#   }

#   frontend_ip_configuration {
#     name                 = local.frontend_ip_configuration_name
#     public_ip_address_id = azurerm_public_ip.appgw_pip.id
#   }

#   backend_address_pool {
#     name = local.backend_address_pool_name
#   }

#   backend_http_settings {
#     name                  = local.http_setting_name
#     cookie_based_affinity = "Disabled"
#     path                  = "/"
#     port                  = 443
#     protocol              = "Https"
#     request_timeout       = 60
#   }

#   http_listener {
#     name                           = local.listener_name
#     frontend_ip_configuration_name = local.frontend_ip_configuration_name
#     frontend_port_name             = local.frontend_port_name
#     protocol                       = "Https"
#   }

#   request_routing_rule {
#     name                       = local.request_routing_rule_name
#     rule_type                  = "Basic"
#     http_listener_name         = local.listener_name
#     backend_address_pool_name  = local.backend_address_pool_name
#     backend_http_settings_name = local.http_setting_name
#   }
# }


