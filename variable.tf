variable "location" {
    default = "eastus"  
}

variable "resource_group_name" {
    default = "DemoResourceGroup"
}

variable "virtual_networks" {
    default = {
        vnet_app = {
            name = "example-network"
            address_space = ["10.0.0.0/16"]
        }
        vnet_acr = {
            name = "acr-network"
            address_space = ["10.1.0.0/16"]
        }
        vnet_hub = { 
            name = "hub-network"
            address_space = ["10.3.0.0/16"]
        }
        vnet_db = {
            name = "db-network"
            address_space = ["10.2.0.0/16"]
        }
    }
}

variable "subnets"  {
    default = {

    ### APP VNET SUBNETS 
    vnet_app_subnet_app = {
        name = "app-subnet"
        address_prefixes = ["10.0.1.0/24"]
        delegation = true
        delegation_name = "Microsoft.Web/serverFarms"
        virtual_network_name = "vnet_app"
        }
    # "key-vault-subnet" = {
    #     address_prefixes = ["10.0.2.0/24"]
    #     delegation = false
    #     delegation_name = ""
    #     }
    vnet_app_subnet_default = {
        name = "default_subnet"
        address_prefixes = ["10.0.0.0/24"]
        delegation = false
        delegation_name = ""
        virtual_network_name = "vnet_app"
        }
    vnet_app_subnet_appgateway = {
        name = "appgateway_subnet"
        address_prefixes = ["10.0.4.0/24"]
        delegation = false
        delegation_name = ""
        virtual_network_name = "vnet_app"
        }  
    vnet_app_subnet_app1endpoint = {
        name = "app1endpoint_subnet"
        address_prefixes = ["10.0.5.0/26"]
        delegation = false
        delegation_name = ""
        virtual_network_name = "vnet_app"
        } 
    vnet_app_subnet_app2endpoint = {
        name = "app2endpoint_subnet"
        address_prefixes = ["10.0.5.64/26"]
        delegation = false
        delegation_name = ""
        virtual_network_name = "vnet_app"
        } 


    ### ACR VNET SUBNETS

    vnet_acr_subnet_acr = {
        name = "acr-subnet"
        address_prefixes = ["10.1.0.0/24"]
        delegation = false
        delegation_name = ""
        virtual_network_name = "vnet_acr"
        }

    ### HUB VNET SUBNETS

    vnet_hub_subnet_default = {
        name = "default-subnet"
        address_prefixes = ["10.3.0.0/24"]
        delegation = false
        delegation_name = ""
        virtual_network_name = "vnet_hub"
        }

    vnet_hub_subnet_firewall = {
        name = "AzureFirewallSubnet"
        address_prefixes = ["10.3.1.0/26"]
        delegation = false
        delegation_name = ""
        virtual_network_name = "vnet_hub"
        }

    ### DB VNET SUBNETS

    vnet_db_subnet_db = {
        name = "mysql-subnet"
        address_prefixes = ["10.2.1.0/26"]
        delegation = true
        delegation_name = "Microsoft.DBforMySQL/flexibleServers"
        virtual_network_name = "vnet_db"
        }
    }
}

### VNET PEERINGS
variable "vnet_peerings" {
    default = { 
        db_to_hub = {
            name = "db-hub"
            virtual_network = "vnet_db"
            remote_virtual_network = "vnet_hub"
        }

        db_to_hub = {
            name = "hub-db"
            virtual_network = "vnet_hub"
            remote_virtual_network = "vnet_db"
        }

        app_to_hub = {
            name = "app-hub"
            virtual_network = "vnet_apps"
            remote_virtual_network = "vnet_hub"
        }

        hub_to_app = {
            name = "hub-app"
            virtual_network = "vnet_hub"
            remote_virtual_network = "vnet_apps"
        }

        acr_to_hub = {
            name = "acr-hub"
            virtual_network = "vnet_acr"
            remote_virtual_network = "vnet_hub"
        }

        hub_to_acr = {
            name = "hub-acr"
            virtual_network = "vnet_hub"
            remote_virtual_network = "vnet_acr"
        }
    }
}

######### route table  !!!!!!!eksik!!!!!!!!!! ###########

variable "route_tables" {
    default = {
        route_table_01 ={
            name = "route-table-01"
            subnet_name = "vnet_app_subnet_app"
            routes =  {
                webapp-acr-allow = {
                    name = "webapp-acr-allow"
                    address_prefix = "10.1.0.0/24"
                    next_hop_type = "VirtualAppliance"
                    next_hop_in_ip_address = "10.3.1.4"
                }
                webapp-db-allow = {
                    name = "webapp-db-allow"
                    address_prefix = "10.2.1.0/26"
                    next_hop_type = "VirtualAppliance"
                    next_hop_in_ip_address = "10.3.1.4"
                }
                db-webapp-allow = {
                    name = "db-webapp-allow"
                    address_prefix = "10.0.1.0/24"
                    next_hop_type = "VirtualAppliance"
                    next_hop_in_ip_address = "10.3.1.4"
                }
            }
        }
    }
}

variable "subnet_route_table_associations" {
    default = {
        route_01_vnet_acr_subnet_acr = {
            subnet = "vnet_acr_subnet_acr"
            route_table = "route_table_01"
        }
        route_01_vnet_db_subnet_db = {
            subnet = "vnet_db_subnet_db"
            route_table = "route_table_01"
        }
    }  
}

variable "public_ip_addresses" {
    default = {
        public_ip_firewall = {
            name = "public_ip_firewall_hub"
            allocation_method = "Static"
            sku = "Standard"
        }
    }
}

variable "firewalls" {
    default = {
        firewall_hub = {
            name = "firewall-hub"
            sku_tier = "Premium"
            ip_configuration_name = "configuration"
            subnet = "vnet_hub_subnet_firewall"
            public_ip_address = "public_ip_firewall"
        }
    }
}

variable "firewall_network_rule_collections" {
    default = {
        firewall_network_rule_collection_01 = {
            name = "firewall_hub"
            firewall = ""
            priority = 100
            action = "Allow"
            firewall_network_rules = {
                "acr-webapp-rule" = {
                    source_addresses = ["10.0.1.0/24"]
                    destination_ports = ["*"]
                    destination_addresses = ["10.1.0.0/24"]
                    protocols = ["Any"]
                }
                "db-webapp-rule" = {
                    source_addresses = ["10.0.1.0/24"]
                    destination_ports = ["*"]
                    destination_addresses = ["10.2.1.0/26"]
                    protocols = ["Any"]
                }
                "acrvm-acr-rule" = {
                    source_addresses = ["10.1.0.4/32"]
                    destination_ports = ["*"]
                    destination_addresses = ["10.1.0.0/24"]
                    protocols = ["Any"]
                }
                "acr-webapp-rule2" = {
                    source_addresses = ["10.1.0.0/24"]
                    destination_ports = ["*"]
                    destination_addresses = ["10.0.1.0/24"]
                    protocols = ["Any"]
                }
            }
        }
    }
}

variable "app_service_plans" {
    default = {
        app_service_plan_coy_phonebook = {
            name = "coyphonebook"
            os_type = "Linux"
            sku_name = "P1v2"
        }
    }
}

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
  default = "azuresshhakan"
}
