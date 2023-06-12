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
        delegation_name = "Microsoft.Web/serverFarms"
        
        }
    "key-vault-subnet" = {
        address_prefixes = ["10.0.2.0/24"]
        delegation = false
        }
    "default_subnet" = {
        address_prefixes = ["10.0.0.0/24"]
        delegation = false
        }
    "acr_subnet" = {
        address_prefixes = ["10.0.3.0/24"]
        delegation = false
        }
    "appgateway_subnet" = {
        address_prefixes = ["10.0.4.0/24"]
        delegation = false
        }  
    "app1endpoint_subnet" = {
        address_prefixes = ["10.0.5.0/26"]
        delegation = false
        } 
    "app2endpoint_subnet" = {
        address_prefixes = ["10.0.5.64/26"]
        delegation = false
        } 
    "mysql_subnet" = {
        address_prefixes = ["10.0.6.0/24"]
        delegation = true
        delegation_name = "Microsoft.DBforMySQL/flexibleServers"

        }
    }
}