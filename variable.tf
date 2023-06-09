variable "vm_name" {
    default = "acr-vm"
}

variable "admin_username" {
    default = "acr-vm"
}

variable "ssh_key_rg" {
    default = "ssh"
}

variable "ssh_key_name" {
  default = "azuresshemre"
}

variable "subnets"  {
    default = {
    "app-subnet" = {
        address_prefixes = ["10.0.1.0/24"]
        delegation = true
        }
    "key-vault-subnet" = {
        address_prefixes = ["10.0.2.0/24"]
        }
    "default_subnet" = {
        address_prefixes = ["10.0.0.0/24"]
        }
    "acr_subnet" = {
        address_prefixes = ["10.0.3.0/24"]
        }
    "appgateway_subnet" = {
        address_prefixes = ["10.0.4.0/24"]
        }  
    "app1endpoint_subnet" = {
        address_prefixes = ["10.0.5.0/26"]
        } 
    "app2endpoint_subnet" = {
        address_prefixes = ["10.0.5.64/26"]
        } 
    "mysql_endpoint_subnet" = {
        address_prefixes = ["10.0.6.0/24"]
        }
    }
}