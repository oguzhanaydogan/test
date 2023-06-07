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
resource "azurerm_resource_group" "rg" {
  name     = "DemoResourceGroup"
  location = "East US"
}
##VNET##
resource "azurerm_virtual_network" "vnet" {
  name                = "example-network"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

module "app" {
  source = "./modules/subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  subnet_name = "app"
  address_prefixes = ["10.0.1.0/24"]
}

module "key_vault" {
  source = "./modules/subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  subnet_name = "key-vault"
  address_prefixes = ["10.0.2.0/24"]
}

module "default" {
  source = "./modules/subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  subnet_name = "default"
  address_prefixes = ["10.0.0.0/24"]
}

module "acr" {
  source = "./modules/subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  subnet_name = "acr"
  address_prefixes = ["10.0.3.0/24"]
}

module "appgateway" {
  source = "./modules/subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  subnet_name = "appgateway"
  address_prefixes = ["10.0.4.0/24"]
}

module "app1endpoint" {
  source = "./modules/subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  subnet_name = "app1endpoint"
  address_prefixes = ["10.0.5.0/26"]
}

module "app2endpoint" {
  source = "./modules/subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  subnet_name = "app2endpoint"
  address_prefixes = ["10.0.5.64/26"]
}
##PUBLIC IP##
resource "azurerm_public_ip" "pip" {
  name                = "DemoPublicIp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

resource "azurerm_service_plan" "example" {
  name                = "oaydoganwebapp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "webapp1" {
  name                = "oaydoganwebapp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.rg.location
  service_plan_id     = azurerm_service_plan.example.id

  site_config {}
}

resource "azurerm_linux_web_app" "webapp2" {
  name                = "oaydoganwebapp2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.rg.location
  service_plan_id     = azurerm_service_plan.example.id

  site_config {}
}

# locals {
#   backend_address_pool_name      = "${azurerm_virtual_network.vnet.name}-beap"
#   frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
#   frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
#   http_setting_name              = "${azurerm_virtual_network.vnet.name}-be-htst"
#   listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
#   request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rqrt"
#   redirect_configuration_name    = "${azurerm_virtual_network.vnet.name}-rdrcfg"
# }

# resource "azurerm_application_gateway" "network" {
#   name                = "DemoApplicationGateway"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location

#   sku {
#     name     = "Standard_Small"
#     tier     = "Standard"
#     sku_name = "V2"
#     capacity = 1
#   }

#   gateway_ip_configuration {
#     name      = "my-gateway-ip-configuration"
#     subnet_id = azurerm_subnet.default.id
#   }

#   frontend_port {
#     name = local.frontend_port_name
#     port = 80
#   }

#   frontend_ip_configuration {
#     name                 = local.frontend_ip_configuration_name
#     public_ip_address_id = azurerm_public_ip.pip.id
#   }

#   backend_address_pool {
#     name = local.backend_address_pool_name
#   }

#   backend_http_settings {
#     name                  = local.http_setting_name
#     cookie_based_affinity = "Disabled"
#     path                  = "/"
#     port                  = 80
#     protocol              = "Http"
#     request_timeout       = 60
#   }

#   http_listener {
#     name                           = local.listener_name
#     frontend_ip_configuration_name = local.frontend_ip_configuration_name
#     frontend_port_name             = local.frontend_port_name
#     protocol                       = "Http"
#   }

#   request_routing_rule {
#     name                       = local.request_routing_rule_name
#     rule_type                  = "Basic"
#     http_listener_name         = local.listener_name
#     backend_address_pool_name  = local.backend_address_pool_name
#     backend_http_settings_name = local.http_setting_name
#   }

#   probe {
#     name = "http80"
#     # host = "127.0.0.1"
#     interval            = 30
#     path                = "/"
#     port                = 80
#     timeout             = 30
#     unhealthy_threshold = 3
#   }
# }

# resource "azurerm_private_dns_zone" "example" {
#   name                = "privatelink.azurewebsites.net"
#   resource_group_name = azurerm_resource_group.rg.name
# }

# data "azurerm_client_config" "current" {}

# resource "azurerm_key_vault" "example" {
#   name                        = "examplekeyvault"
#   location                    = azurerm_resource_group.rg.location
#   resource_group_name         = azurerm_resource_group.rg.name
#   enabled_for_disk_encryption = true
#   tenant_id                   = data.azurerm_client_config.current.tenant_id
#   soft_delete_retention_days  = 7
#   purge_protection_enabled    = false
#   enable_rbac_authorization = true
#   public_network_access_enabled = false
  

#   sku_name = "standard"

#   access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = data.azurerm_client_config.current.object_id

#     key_permissions = [
#       "Get",
#     ]

#     secret_permissions = [
#       "Get",
#     ]

#     storage_permissions = [
#       "Get",
#     ]
#   }
# }


resource "azurerm_container_registry" "acr" {
  name                          = var.acr_name
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  admin_enabled                 = false
  sku                           = "Premium"
  public_network_access_enabled = false
}

# Create azure container registry private endpoint
resource "azurerm_private_dns_zone" "acr_private_dns_zone" {
  name                = "privatelink.azurecr.io"
  resource_group_name =  azurerm_resource_group.rg.name
}

# Create azure private dns zone virtual network link for acr private endpoint vnet
resource "azurerm_private_dns_zone_virtual_network_link" "acr_private_dns_zone_virtual_network_link" {
  name                  = "${var.acr_name}-private-dns-zone-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.acr_private_dns_zone.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Create azure private endpoint
resource "azurerm_private_endpoint" "acr_private_endpoint" {
  name                = "${var.acr_name}-private-endpoint"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = module.acr.id
  
  
  private_service_connection {
    name                           = "${var.acr_name}-service-connection"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names = [
      "registry"
    ]
  }
  
  private_dns_zone_group {
    name = "${var.acr_name}-private-dns-zone-group"
    
    private_dns_zone_ids = [
      azurerm_private_dns_zone.acr_private_dns_zone.id
    ]  
  }
 
  depends_on = [
    azurerm_virtual_network.vnet,
    module.acr,
    azurerm_container_registry.acr
  ]
}