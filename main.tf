terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.61.0"
    }
  }
  
  # backend "azurerm" {
  #   resource_group_name  = "coy-backend"
  #   storage_account_name = "coystorage"
  #   container_name       = "terraformstate"
  #   key                  = "terraform.tfstate"
  # }
}

provider "azurerm" {
  features{}
  skip_provider_registration = true
}

#RG##
module "resourcegroup" {
  source = "./modules/ResourceGroup"
  location = var.location
  name = var.resource_group_name
}

####example-network
module "virtualnetworks" {
  source = "./modules/VirtualNetwork"
  for_each = var.virtual_networks
  location = module.resourcegroup.location
  resource_group_name = module.resourcegroup.name
  name = each.value.name
  address_space = each.value.name
}

# module "virtualnetwork2" {
#   source = "./modules/VirtualNetwork"
#   name = "acr-network"
#   location = module.resourcegroup.location
#   resource_group_name = module.resourcegroup.name
#   address_space = ["10.1.0.0/16"]
# }

# module "hub_virtual_network" {
#   source = "./modules/VirtualNetwork"
#   name = "hub-network"
#   location = module.resourcegroup.location
#   resource_group_name = module.resourcegroup.name
#   address_space = ["10.3.0.0/16"]
# }

# module "db_network" {
#   source = "./modules/VirtualNetwork"
#   name = "db-network"
#   location = module.resourcegroup.location
#   resource_group_name = module.resourcegroup.name
#   address_space = ["10.2.0.0/16"]
# }


module "subnets" {
  source = "./modules/subnet"
  for_each = var.subnets
  resource_group_name = module.resourcegroup.name
  virtual_network_name = module.virtual_networks["${each.value.virtual_network_name}"].name
  subnet_name = each.value.name
  address_prefixes = each.value.address_prefixes
  delegation = each.value.delegation
  delegation_name = each.value.delegation_name
}

##### acr-network


# module "subnetacr" {
#   source = "./modules/subnet"
#   resource_group_name = module.resourcegroup.name
#   virtual_network_name = module.virtualnetwork2.name
#   subnet_name = "acr-subnet"
#   address_prefixes = ["10.1.0.0/24"]
#   delegation = false
#   delegation_name = ""
# }

#### hub-network

# module "hub_default" {
#   source = "./modules/subnet"
#   resource_group_name = module.resourcegroup.name
#   virtual_network_name = module.hub_virtual_network.name
#   subnet_name = "default"
#   address_prefixes = ["10.3.0.0/24"]
#   delegation = false
#   delegation_name = ""
# }

# module "firewall_subnet" {
#   source = "./modules/subnet"
#   resource_group_name = module.resourcegroup.name
#   virtual_network_name = module.hub_virtual_network.name
#   subnet_name = "AzureFirewallSubnet"
#   address_prefixes = ["10.3.1.0/26"]
#   delegation = false
#   delegation_name = ""
# }

#### db-network
# module "db_subnet" {
#   source = "./modules/subnet"
#   resource_group_name = module.resourcegroup.name
#   virtual_network_name = module.db_network.name
#   subnet_name = "mysql-subnet"
#   address_prefixes = ["10.2.1.0/26"]
#   delegation = true
#   delegation_name = "Microsoft.DBforMySQL/flexibleServers"
# }

module "vnet_peerings" {
  source = "./modules/vnetpeering"
  for_each = var.vnet_peerings
  resource_group_name = module.resourcegroup.name
  name = each.value.name
  virtual_network_name = module.virtualnetworks["${each.value.virtual_network}"].name
  remote_virtual_network_id = module.virtualnetworks["${each.value.remote_virtual_network}"].id
  
}

# module "vnet_peering_db_hub" {
#   source = "./modules/vnetpeering"
#   name = "db-hub"
#   resource_group_name = module.resourcegroup.name
#   virtual_network_name = module.db_network.name
#   remote_virtual_network_id = module.hub_virtual_network.id
# }

# module "vnet_peering_hub_db" {
#   source = "./modules/vnetpeering"
#   name = "hub-db"
#   resource_group_name = module.resourcegroup.name
#   virtual_network_name = module.hub_virtual_network.name
#   remote_virtual_network_id = module.db_network.id
# }

# module "vnet_peering_example_hub" {
#   source = "./modules/vnetpeering"
#   name = "example-hub"
#   resource_group_name = module.resourcegroup.name
#   virtual_network_name = module.virtualnetwork.name
#   remote_virtual_network_id = module.hub_virtual_network.id
# }

# module "vnet_peering_hub_example" {
#   source = "./modules/vnetpeering"
#   name = "hub-example"
#   resource_group_name = module.resourcegroup.name
#   virtual_network_name = module.hub_virtual_network.name
#   remote_virtual_network_id = module.virtualnetwork.id
# }

# module "vnet_peering_acr_hub" {
#   source = "./modules/vnetpeering"
#   name = "acr-hub"
#   resource_group_name = module.resourcegroup.name
#   virtual_network_name = module.virtualnetwork2.name
#   remote_virtual_network_id = module.hub_virtual_network.id
# }

# module "vnet_peering_hub_acr" {
#   source = "./modules/vnetpeering"
#   name = "hub-acr"
#   resource_group_name = module.resourcegroup.name
#   virtual_network_name = module.hub_virtual_network.name
#   remote_virtual_network_id = module.virtualnetwork2.id
# }

module "route_tables" {
  source = "./modules/RouteTable"
  for_each = var.route_tables
  resource_group_name = module.resourcegroup.name
  location = module.resourcegroup.location
  name = each.value.name
  route = each.value.routes
  subnet_id = module.subnets["${each.value.subnet_name}"].id
  subnet_route_table_associations = each.value.subnet_route_table_associations
}

module "subnet_route_table_associations" {
  source = "./modules/RouteTableExtraAssociation"
  for_each = var.subnet_route_table_associations
  subnet_id = module.subnets["${each.value.subnet}"].id
  route_table_id = module.route_tables["${each.value.route_table}"].id
}
# resource "azurerm_subnet_route_table_association" "example" {
#   subnet_id      = module.subnetacr.id
#   route_table_id = module.routetable_webapptoacr.id
# }

# resource "azurerm_subnet_route_table_association" "db_association" {
#   subnet_id      = module.db_subnet.id
#   route_table_id = module.routetable_webapptoacr.id
# }

module "public_ip_addresses" {
  source = "./modules/PublicIPAddress"
  for_each = var.public_ip_addresses
  resource_group_name = module.resourcegroup.name
  location = module.resourcegroup.location
  name = each.value.name
  allocation_method = each.value.allocation_method
  sku = each.value.sku
}

module "firewalls" {
  source = "./modules/AzureFirewall"
  for_each = var.firewalls
  location = module.resourcegroup.location
  resource_group_name = module.resourcegroup.name
  name = each.value.name
  sku_tier = each.value.sku_tier
  subnet_id = module.subnets["${each.value.subnet}"].id
  public_ip_address_id = module.public_ip_addresses["${each.value.public_ip_address}"].id
}

# resource "azurerm_firewall" "hub_firewall" {
#   name                = lookup(var.hub_firewall_config,"name")
#   location            = module.resourcegroup.location
#   resource_group_name = module.resourcegroup.name
#   sku_name            = "AZFW_VNet"
#   sku_tier            = "Premium"

#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = module.firewall_subnet.id
#     public_ip_address_id = azurerm_public_ip.hubwall_pip.id
#   }
# }

module "firewall_network_rule_collections" {
  source = "./modules/AzureFirewallNetworkRuleCollection"
  for_each = var.firewall_network_rule_collections
  resource_group_name = module.resourcegroup.name
  name = each.value.name
  firewall = module.firewalls["${each.value.firewall}"].name
  priority = each.value.priority
  action = each.value.action
  firewall_network_rules = each.value.firewall_network_rules
}

# resource "azurerm_firewall_network_rule_collection" "example" {
#   name                = "testcollection"
#   azure_firewall_name = azurerm_firewall.hub_wall.name
#   resource_group_name = module.resourcegroup.name
#   priority            = 100
#   action              = "Allow"

#    dynamic "rule" {
#     for_each = var.network_firewall_rules
#     content {
#         name = rule.key
#         source_addresses = rule.value.source_addresses
#         destination_ports = rule.value.destination_ports
#         destination_addresses = rule.value.destination_addresses
#         protocols = rule.value.protocols
#     }    
#   }
# }


# resource "azurerm_public_ip" "hubwall_pip" {
#   name                = "hubwallpip"
#   location            = module.resourcegroup.location
#   resource_group_name = module.resourcegroup.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

module "app_service_plans" {
  source = "./modules/AppServicePlan"
  for_each = var.app_service_plans
  resource_group_name = module.resourcegroup.name
  location = module.resourcegroup.location
  name = each.value.name
  os_type = each.value.os_type
  sku_name = each.value.sku_name
}

# resource "azurerm_service_plan" "example" {
#   name                = "oaydoganwebapp"
#   resource_group_name = module.resourcegroup.name
#   location            = module.resourcegroup.location
#   os_type             = "Linux"
#   sku_name            = "P1v2"
# }

module "key_vault_secrets" {
  source = "./modules/KeyVaultSecret"
  for_each = var.key_vault_secrets
  key_vault = each.value.key_vault
  key_vault_resource_group = each.value.key_vault_resource_group
  secret = each.value.secret
}
# data "azurerm_key_vault" "example" {
#   name                = "keyvault-coy"
#   resource_group_name = "ssh"
# }

# data "azurerm_key_vault_secret" "db_password" {
#   name         = "MYSQLPASSWORD"
#   key_vault_id = data.azurerm_key_vault.example.id
#   depends_on = [ azurerm_key_vault_access_policy.kvaccess ]
# }

module "key_vault_access_policies" {
  source = "./modules/KeyVaultAccessPolicy"
  for_each = var.key_vault_access_policies
  key_vault = each.value.key_vault
  key_vault_resource_group = each.value.key_vault_resource_group
  key_permissions = each.value.key_permissions
  secret_permissions = each.value.secret_permissions  
}

# data "azurerm_client_config" "current" {}

# resource "azurerm_key_vault_access_policy" "kvaccess" {
#   key_vault_id = data.azurerm_key_vault.example.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = data.azurerm_client_config.current.object_id

#   key_permissions = [
#     "Get", "List",
#   ]
#   secret_permissions = [
#     "Get", "List",
#   ]
# }

module "role_assignments" {
  source = "./modules/RoleAssignment"
  for_each = var.role_assignments
  scope = module.acrs["${each.value.scope}"].id
  principal_id = module.app_services["${each.value.principal_id}"].principal_id
  role_definition = each.value.role_definition
}

# resource "azurerm_role_assignment" "web1_role_assignment" {
#   scope              = module.ACR.id
#   principal_id       = module.webapp1.key_vault_reference_identity_id
#   role_definition_name = "AcrPull"
# }

module "app_services" {
  source = "./modules/AppService"
  for_each = var.app_services
  locals {

  # app insights
  app_insights = azurerm_application_insights.insight.0
  app_settings_insights = each.value.application_insights_enabled ? {
    APPINSIGHTS_INSTRUMENTATIONKEY             = try(local.app_insights.instrumentation_key, "")
    APPLICATIONINSIGHTS_CONNECTION_STRING      = try(local.app_insights.connection_string, "")
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
  } : {}
  common_app_settings = {
    "MYSQL_PASSWORD"=module.key_vault_secrets["${each.value.mysql_password_secret}"].id
    "MYSQL_DATABASE_HOST"=module.mysql.host
    "MYSQL_DATABASE"=module.mysql.database_name
    "MYSQL_USER"=module.mysql.database_username
    "DOCKER_REGISTRY_SERVER_URL"=module.ACR.fqdn
    "WEBSITE_PULL_IMAGE_OVER_VNET"=true}
}
  resource_group_name = module.resourcegroup.name
  location = module.resourcegroup.location
  service_plan_id = module.app_service_plans["${each.value.app_service_plan}"].id
  app_settings = merge(local.app_settings_insights, local.common_app_settings)
  vnet_integration_subnet = module.subnets["${each.value.vnet_integration_subnet}"].id
}

# module "webapp1" {
#   source = "./modules/webapp"
#   name = lookup(var.app_service_01_config,"name")
#   resource_group_name = module.resourcegroup.name
#   location = module.resourcegroup.location
#   service_plan_id = module.app_service_plans["${lookup(var.app_service_01_config,"serviceplan")}"].id
  
#   app_settings = {
#     "MYSQL_PASSWORD"=module.key_vault_secrets["key_vault_secret_mysql_password"].id
#     "MYSQL_PASSWORD"=data.azurerm_key_vault_secret.db_password.id
#     "MYSQL_DATABASE_HOST"=module.mysql.host
#     "MYSQL_DATABASE"=module.mysql.database_name
#     "MYSQL_USER"=module.mysql.database_username
#     "APPINSIGHTS_INSTRUMENTATIONKEY"=azurerm_application_insights.insight.instrumentation_key
#     "APPLICATIONINSIGHTS_CONNECTION_STRING"=azurerm_application_insights.insight.connection_string
#     "ApplicationInsightsAgent_EXTENSION_VERSION"="~3"
#     "DOCKER_REGISTRY_SERVER_URL"=module.ACR.fqdn
#     "WEBSITE_PULL_IMAGE_OVER_VNET"=true
#     }
# }



# resource "azurerm_role_assignment" "web2_role_assignment" {
#   scope              = module.ACR.id
#   principal_id       = module.webapp2.key_vault_reference_identity_id
#   role_definition_name = "AcrPull"
# }
# module "webapp2" {
#   source = "./modules/webapp"
#   name = "coywebapp-2"
#   resource_group_name = module.resourcegroup.name
#   location = module.resourcegroup.location
#   service_plan_id = azurerm_service_plan.example.id
#   app_settings = {
#     "MYSQL_PASSWORD"=data.azurerm_key_vault_secret.db_password.id
#     "MYSQL_DATABASE_HOST"=module.mysql.host
#     "MYSQL_DATABASE"=module.mysql.database_name
#     "MYSQL_USER"=module.mysql.database_username  
#     "DOCKER_REGISTRY_SERVER_URL"=module.ACR.fqdn  
#     "WEBSITE_PULL_IMAGE_OVER_VNET"=true
#     }
#   }

# resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration1" {
#   app_service_id = module.webapp1.id
#   subnet_id      = module.subnets["app-subnet"].id
# }

# resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration2" {
#   app_service_id = module.webapp2.id
#   subnet_id      = module.subnets["app-subnet"].id
# }

module "acrs" {
  source = "./modules/AzureContainerRegistry"
  for_each = var.acrs
  name = each.value.name
  resource_group_name = module.resourcegroup.name
  location = module.resourcegroup.location
  admin_enabled = each.value.admin_enabled
  sku = each.value.sku
  public_network_access_enabled = each.value.public_network_access_enabled
  network_rule_bypass_option = each.value.network_rule_bypass_option
}

module "private_dns_zones" {
  source = "./modules/privatednszonewithlink"
  for_each = var.private_dns_zones
  resourcegroup = module.resourcegroup.name
  virtual_network_id = module.networks["${each.value.virtual_network}"].id
  link_name = each.value.link_name
  name = each.value.dns_zone_name
}
# module "private_dns_zone_acr" {
#   source = "./modules/privatednszonewithlink"
#   name = "privatelink.azurecr.io"
#   resourcegroup = module.resourcegroup.name
#   virtual_network_id = module.virtualnetwork2.id
#   attached_resource_name = module.ACR.name
# }
module "private_dns_zone_extra_links" {
  source = "./modules/privatednszoneextralink"
  for_each = var.private_dns_zone_extra_links
  resourcegroup = module.resourcegroup.name
  name = each.value.link_name
  virtual_network_id = module.virtualnetworks["${each.value.virtual_network}"].id
  private_dns_zone_name = module.private_dns_zones["${each.value.private_dns_zone}"].name
}
# module "private_dns_zone_acr_link_example" {
#   source = "./modules/privatednszoneextralink"
#   resourcegroup = module.resourcegroup.name
#   name = "private-dns-zone-acr-link-example"
#   virtual_network_id = module.virtualnetwork.id
#   private_dns_zone_name = module.private_dns_zone_acr.name
# }

module "private_dns_zone_acr_link_hub" {
  source = "./modules/privatednszoneextralink"
  resourcegroup = module.resourcegroup.name
  name = "private-dns-zone-acr-link-hub"
  virtual_network_id = module.hub_virtual_network.id
  private_dns_zone_name = module.private_dns_zone_acr.name
}

module "private_endpoint_acr" {
    source = "./modules/privateendpoint"
    resourcegroup = module.resourcegroup.name
    location = module.resourcegroup.location
    subnet_id = module.subnetacr.id
    private_dns_zone_ids = ["${module.private_dns_zone_acr.id}"]
    attached_resource_name = module.ACR.name
    attached_resource_id = module.ACR.id
    subresource_name = "registry"
}

module "private_dns_zone_apps" {
  source = "./modules/privatednszonewithlink"
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
  delegated_subnet_id = module.db_subnet.id
  private_dns_zone_id = module.private_dns_zone_mysql.id
  zone = "1"
  depends_on = [ module.private_dns_zone_mysql ]
}

module "private_dns_zone_mysql" {
  source = "./modules/privatednszonewithlink"
  name = "privatelink.mysql.database.azure.com"
  resourcegroup = module.resourcegroup.name
  attached_resource_name = "coy-database-server"
  virtual_network_id = module.db_network.id
}

module "private_dns_zone_mysql_link_example" {
  source = "./modules/privatednszoneextralink"
  resourcegroup = module.resourcegroup.name
  name = "private-dns-zone-mysql-link-example"
  virtual_network_id = module.virtualnetwork.id
  private_dns_zone_name = module.private_dns_zone_mysql.name
}

module "private_dns_zone_db_link_hub" {
  source = "./modules/privatednszoneextralink"
  resourcegroup = module.resourcegroup.name
  name = "private-dns-zone-mysql-link-hub"
  virtual_network_id = module.hub_virtual_network.id
  private_dns_zone_name = module.private_dns_zone_mysql.name
}

resource "azurerm_virtual_machine" "vm1" {
  name                  = var.vm_name
  location              = module.resourcegroup.location
  resource_group_name   = module.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_D2s_v3"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  depends_on = [ module.ACR ]
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
    subnet_id                     = module.subnetacr.id
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

resource "azurerm_role_assignment" "example" {
  scope                = module.ACR.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_virtual_machine.vm1.identity[0].principal_id
}

resource "azurerm_role_assignment" "example2" {
  scope                = module.webapp1.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_virtual_machine.vm1.identity[0].principal_id
}

resource "azurerm_role_assignment" "example3" {
  scope                = module.webapp2.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_virtual_machine.vm1.identity[0].principal_id
}

resource "azurerm_application_insights" "insight" {
  name                = "tf-test-appinsights"
  location            = module.resourcegroup.location
  resource_group_name = module.resourcegroup.name
  application_type    = "web"
}

resource "azurerm_public_ip" "appgw_pip" {
  name                = "PublicFrontendIpIPv4"
  resource_group_name = module.resourcegroup.name
  location            = module.resourcegroup.location
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "coy-appgateway"
  resource_group_name = module.resourcegroup.name
  location            = module.resourcegroup.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = module.subnets["appgateway_subnet"].id
  }

  frontend_port {
    name = "feport"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = "apps-backend-pool"
    fqdns = [module.webapp1.fqdn, module.webapp2.fqdn]
  }
  ###APPS
  backend_http_settings {
    name                  = "apps-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "apps-probe"
    pick_host_name_from_backend_address = true
    path = "/"
  }
  probe {
    name                = "apps-probe"
    pick_host_name_from_backend_http_settings = true
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 80
    path                = "/"
  }
  ##app1##
    backend_address_pool {
    name = "app1-backend-pool"
    fqdns = [module.webapp1.fqdn]
  }
  backend_http_settings {
    name                  = "app1-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "app1-probe"
    pick_host_name_from_backend_address = true
    path = "/"
  }
  probe {
    name                = "app1-probe"
    pick_host_name_from_backend_http_settings = true
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 80
    path                = "/"
  }  

  ####app2####
  backend_address_pool {
    name = "app2-backend-pool"
    fqdns = [module.webapp2.fqdn]
  }
  backend_http_settings {
    name                  = "app2-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "app2-probe"
    pick_host_name_from_backend_address = true
    path = "/"
  }
  probe {
    name                = "app2-probe"
    pick_host_name_from_backend_http_settings = true
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 80
    path                = "/"
  } 

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "feport"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule"
    rule_type                  = "PathBasedRouting"
    http_listener_name         = "listener"
    backend_address_pool_name  = "apps-backend-pool"
    backend_http_settings_name = "apps-http-settings"    
    url_path_map_name = "path-map1"
    priority = "110"
  }

  url_path_map{
    name = "path-map1"
    default_backend_http_settings_name = "apps-http-settings"
    default_backend_address_pool_name  = "apps-backend-pool"
    path_rule{
      name = "path1"
      paths = ["/web"]
      backend_address_pool_name = "app1-backend-pool"
      backend_http_settings_name = "app1-http-settings"
    }
    path_rule{
      name = "path2"
      paths = ["/result"]
      backend_address_pool_name = "app2-backend-pool"
      backend_http_settings_name = "app2-http-settings"
    }
  }
}


