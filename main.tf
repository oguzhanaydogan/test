terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "1.38.0"
    }
  }
}

provider "azurerm" {
  features {
  }
}
             ##RG##
resource "azurerm_resource_group" "rg" {
  name     = "DemoResourceGroup"
  location = "East US"
}
             ##VNET##
resource "azurerm_virtual_network" "vnet" {
name = "example-network"
location = azurerm_resource_group.rg.location
resource_group_name = azurerm_resource_group.rg.name
address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "apps" {
 name = "Apps"
 resource_group_name = azurerm_resource_group.rg.name
 virtual_network_name = azurerm_virtual_network.vnet.name
 address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "default" {
 name = "default"
 resource_group_name = azurerm_resource_group.rg.name
 virtual_network_name = azurerm_virtual_network.vnet.name
 address_prefixes = ["10.0.0.0/24"]
}
           ##PUBLIC IP##
resource "azurerm_public_ip" "pip" {
name = "DemoPublicIp"
resource_group_name = azurerm_resource_group.rg.name
location = azurerm_resource_group.rg.location
allocation_method = "Static"
}

resource "azurerm_service_plan" "example" {
name = "oaydoganwebapp"
resource_group_name = azurerm_resource_group.rg.name
location = azurerm_resource_group.rg.location
os_type = "Linux"
sku_name = "P1v2"
}

resource "azurerm_linux_web_app" "example" {
name = "example"
resource_group_name = azurerm_resource_group.rg.name
location = azurerm_service_plan.example.location
service_plan_id = azurerm_service_plan.example.id

site_config {}
}

locals {
backend_address_pool_name = "${azurerm_virtual_network.vnet.name}-beap"
frontend_port_name = "${azurerm_virtual_network.vnet.name}-feport"
frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
http_setting_name = "${azurerm_virtual_network.vnet.name}-be-htst"
listener_name = "${azurerm_virtual_network.vnet.name}-httplstn"
request_routing_rule_name = "${azurerm_virtual_network.vnet.name}-rqrt"
redirect_configuration_name = "${azurerm_virtual_network.vnet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
name = "DemoApplicationGateway"
resource_group_name = azurerm_resource_group.rg.name
location = azurerm_resource_group.rg.location

sku {
name = "Standard_Small"
tier = "Standard"
sku_name = "V2"
capacity = 1
}

gateway_ip_configuration {
name = "my-gateway-ip-configuration"
subnet_id = azurerm_subnet.default.id
}

frontend_port {
name = local.frontend_port_name
port = 80
}

frontend_ip_configuration {
name = local.frontend_ip_configuration_name
public_ip_address_id = azurerm_public_ip.pip.id
}

backend_address_pool {
name = local.backend_address_pool_name
}

backend_http_settings {
name = local.http_setting_name
cookie_based_affinity = "Disabled"
path = "/"
port = 80
protocol = "Http"
request_timeout = 60
}

http_listener {
name = local.listener_name
frontend_ip_configuration_name = local.frontend_ip_configuration_name
frontend_port_name = local.frontend_port_name
protocol = "Http"
}

request_routing_rule {
name = local.request_routing_rule_name
rule_type = "Basic"
http_listener_name = local.listener_name
backend_address_pool_name = local.backend_address_pool_name
backend_http_settings_name = local.http_setting_name
}

probe {
name = "http80"
# host = "127.0.0.1"
interval = 30
path = "/"
port = 80
timeout = 30
unhealthy_threshold = 3
  } 
}


resource "azurerm_private_dns_zone" "example" {
name = "privatelink.azurewebsites.net"
resource_group_name = azurerm_resource_group.rg.name
}