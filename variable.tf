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
        delegation_name = ""
        }
    "default_subnet" = {
        address_prefixes = ["10.0.0.0/24"]
        delegation = false
        delegation_name = ""
        }
    # "acr_subnet" = {
    #     address_prefixes = ["10.0.3.0/24"]
    #     delegation = false
    #     delegation_name = ""
    #     }
    "appgateway_subnet" = {
        address_prefixes = ["10.0.4.0/24"]
        delegation = false
        delegation_name = ""
        }  
    "app1endpoint_subnet" = {
        address_prefixes = ["10.0.5.0/26"]
        delegation = false
        delegation_name = ""
        } 
    "app2endpoint_subnet" = {
        address_prefixes = ["10.0.5.64/26"]
        delegation = false
        delegation_name = ""
        } 
    "mysql_subnet" = {
        address_prefixes = ["10.0.6.0/24"]
        delegation = true
        delegation_name = "Microsoft.DBforMySQL/flexibleServers"

        }
    }
}

variable "network_firewall_rules" {
    default = {
        "acr-webapp-rule" = {
            source_addresses = ["10.0.1.0/24"]
            destination_ports = ["*"]
            destination_addresses = ["10.1.0.0/24"]
            protocols = ["Any"]
    }
  }
}

variable "route" {
    default = {
        "webapp-acr-allow" = {
            address_prefix = "10.1.0.0/24"
            next_hop_type = "VirtualAppliance"
            next_hop_in_ip_address = "10.2.1.4"
        }
        # "internet" = {
        #     address_prefix = "0.0.0.0/0"
        #     next_hop_type = "Internet"
        # }
    }
}