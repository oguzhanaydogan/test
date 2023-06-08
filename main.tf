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

module "app_subnet" {
  source = "./modules/subnet"
  resource_group_name = module.resourcegroup.name
  virtual_network_name = module.virtualnetwork.name
  subnet_name = "app"
  address_prefixes = ["10.0.1.0/24"]
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
resource "azurerm_service_plan" "example" {
  name                = "oaydoganwebapp"
  resource_group_name = module.resourcegroup.name
  location            = module.resourcegroup.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

module "webapp1" {
  source = "./modules/webapp"
  name = "coywebapp1"
  resource_group_name = module.resourcegroup.name
  location = module.resourcegroup.location
  service_plan_id = azurerm_service_plan.example.id
}

module "webapp2" {
  source = "./modules/webapp"
  name = "coywebapp2"
  resource_group_name = module.resourcegroup.name
  location = module.resourcegroup.location
  service_plan_id = azurerm_service_plan.example.id
}

module "ACR" {
  source = "./modules/AzureContainerRegistry"
  name = "coyhub"
  resource_group_name = module.resourcegroup.name
  location = module.resourcegroup.location
}

# Create azure container registry private endpoint
resource "azurerm_private_dns_zone" "acr_private_dns_zone" {
  name                = "privatelink.azurecr.io"
  resource_group_name =  module.resourcegroup.name
}

# Create azure private dns zone virtual network link for acr private endpoint vnet
resource "azurerm_private_dns_zone_virtual_network_link" "acr_private_dns_zone_virtual_network_link" {
  name                  = "${module.ACR.name}-private-dns-zone-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.acr_private_dns_zone.name
  resource_group_name   = module.resourcegroup.name
  virtual_network_id    = module.virtualnetwork.id
}

# Create azure private endpoint
resource "azurerm_private_endpoint" "acr_private_endpoint" {
  name                = "${module.ACR.name}-private-endpoint"
  resource_group_name = module.resourcegroup.name
  location            = module.resourcegroup.location
  subnet_id           = module.acr_subnet.id
  
  
  private_service_connection {
    name                           = "${module.ACR.name}-service-connection"
    private_connection_resource_id = module.ACR.id
    is_manual_connection           = false
    subresource_names = [
      "registry"
    ]
  }
  
  private_dns_zone_group {
    name = "${module.ACR.name}-private-dns-zone-group"
    
    private_dns_zone_ids = [
      azurerm_private_dns_zone.acr_private_dns_zone.id
    ]  
  }
 
  depends_on = [
    module.virtualnetwork,
    module.acr_subnet,
    module.ACR
  ]
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

