terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.59.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.39.0"
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

provider "azuread" {
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

module "app_subnet" {
  source = "./modules/subnet"
  resource_group_name = module.resourcegroup.name
  virtual_network_name = module.virtualnetwork.name
  subnet_name = "app"
  address_prefixes = ["10.0.1.0/24"]
  delegation = true
}

module "key_vault_subnet" {
  source = "./modules/subnet"
  resource_group_name = module.resourcegroup.name
  virtual_network_name = module.virtualnetwork.name
  subnet_name = "key-vault"
  address_prefixes = ["10.0.2.0/24"]
}

module "default_subnet" {
  source = "./modules/subnet"
  resource_group_name = module.resourcegroup.name
  virtual_network_name = module.virtualnetwork.name
  subnet_name = "default"
  address_prefixes = ["10.0.0.0/24"]
}

module "acr_subnet" {
  source = "./modules/subnet"
  resource_group_name = module.resourcegroup.name
  virtual_network_name = module.virtualnetwork.name
  subnet_name = "acr"
  address_prefixes = ["10.0.3.0/24"]
}

module "appgateway_subnet" {
  source = "./modules/subnet"
  resource_group_name = module.resourcegroup.name
  virtual_network_name = module.virtualnetwork.name
  subnet_name = "appgateway"
  address_prefixes = ["10.0.4.0/24"]
}

module "app1endpoint_subnet" {
  source = "./modules/subnet"
  resource_group_name = module.resourcegroup.name
  virtual_network_name = module.virtualnetwork.name
  subnet_name = "app1endpoint"
  address_prefixes = ["10.0.5.0/26"]
}

module "app2endpoint_subnet" {
  source = "./modules/subnet"
  resource_group_name = module.resourcegroup.name
  virtual_network_name = module.virtualnetwork.name
  subnet_name = "app2endpoint"
  address_prefixes = ["10.0.5.64/26"]
}

module "mysql_endpoint_subnet" {
  source = "./modules/subnet"
  resource_group_name = module.resourcegroup.name
  virtual_network_name = module.virtualnetwork.name
  subnet_name = "mysql_endpoint"
  address_prefixes = ["10.0.6.0/24"]
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

data "azuread_service_principal" "example" {
  display_name = "azure-cli-2023-06-08-16-04-04"
}

resource "azurerm_key_vault_access_policy" "kvaccess" {
  key_vault_id = data.azurerm_key_vault.example.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_service_principal.current.object_id

  key_permissions = [
    "Get", "List",
  ]
  secret_permissions = [
    "Get", "List",
  ]
}
module "webapp1" {
  source = "./modules/webapp"
  name = "coywebapp1"
  resource_group_name = module.resourcegroup.name
  location = module.resourcegroup.location
  service_plan_id = azurerm_service_plan.example.id
  app_settings = {
    "MYSQLPASSWORD"=data.azurerm_key_vault_secret.db_password.value
    }
}

module "webapp2" {
  source = "./modules/webapp"
  name = "coywebapp2"
  resource_group_name = module.resourcegroup.name
  location = module.resourcegroup.location
  service_plan_id = azurerm_service_plan.example.id
    app_settings = {
    "MYSQLPASSWORD"=data.azurerm_key_vault_secret.db_password.value
    }
  }

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration1" {
  app_service_id = module.webapp1.id
  subnet_id      = module.app_subnet.id
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration2" {
  app_service_id = module.webapp2.id
  subnet_id      = module.app_subnet.id
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
    subnet_id = module.acr_subnet.id
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
    subnet_id = module.app1endpoint_subnet.id
    private_dns_zone_ids = ["${module.private_dns_zone_apps.id}"]
    attached_resource_name = module.webapp1.name
    attached_resource_id = module.webapp1.id
    subresource_name = "sites"
}

module "private_endpoint_app2" {
    source = "./modules/privateendpoint"
    resourcegroup = module.resourcegroup.name
    location = module.resourcegroup.location
    subnet_id = module.app2endpoint_subnet.id
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
  admin_username = "coy-admin"
  admin_password = data.azurerm_key_vault_secret.db_password.value
}

module "private_dns_zone_mysql" {
  source = "./modules/privatednszone"
  name = "privatelink.mysql.database.azure.com"
  resourcegroup = module.resourcegroup.name
  attached_resource_name = module.mysql.name
  virtual_network_id = module.virtualnetwork.id
}

module "private_endpoint_mysql" {
  source = "./modules/privateendpoint"
  attached_resource_name = module.mysql.name
  resourcegroup = module.resourcegroup.name
  location = module.resourcegroup.location
  subnet_id = module.mysql_endpoint_subnet.id
  attached_resource_id = module.mysql.id
  private_dns_zone_ids = ["${module.private_dns_zone_mysql.id}"]
  subresource_name = "mysqlServer"
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
    subnet_id                     = module.acr_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip1.id
  }
}


data "azurerm_ssh_public_key" "ssh_public_key" {
  resource_group_name = var.ssh_key_rg
  name                = var.ssh_key_name
}

# data "template_file" "userdata" {
#   template = file("${abspath(path.module)}/userdata.sh")
# }

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
  scope              = data.azurerm_subscription.current.id
  role_definition_id = "${data.azurerm_subscription.current.id}${data.azurerm_role_definition.acrpush.id}"
  principal_id       = azurerm_virtual_machine.vm1.identity[0].principal_id
}

