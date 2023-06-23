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

### route tables  
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
        public_ip_firewall_hub = {
            name = "public_ip_firewall_hub"
            allocation_method = "Static"
            sku = "Standard"
        }
        public_ip_app_gateway = {
            name = "PublicFrontendIpIPv4"
            allocation_method = "Static"
            sku = "Standard"
        }
        public_ip_virtual_machine_01 = {
            name = "public-ip-vm-custom-agent"
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

variable "app_services" {
    default = {
        app_service_01 = {
            name = "coywebapp-1"
            service_plan = "app_service_plan_coy_phonebook"
            mysql_password_secret = "key_vault_secret_mysql_password"
            application_insights_enabled=true
            vnet_integration_subnet = "vnet_app_subnet_app"            
        }   
        app_service_02 = {
            name = "coywebapp-2"
            service_plan = "app_service_plan_coy_phonebook"
            mysql_password_secret = "key_vault_secret_mysql_password"
            application_insights_enabled=false
            vnet_integration_subnet = "vnet_app_subnet_app"
        }
    }
}


variable "key_vault_secrets" {
    default = {
        key_vault_secret_mysql_password ={
            key_vault = "keyvault-coy"
            key_vault_resource_group = "ssh"
            secret = "MYSQLPASSWORD"
        }
    } 
}

variable "key_vault_access_policies" {
    default = {
        key_vault_access_policy_coy_vault = {
            key_vault = "keyvault-coy"
            key_vault_resource_group = "ssh"
            key_permissions = [
                "Get", "List",
            ]
            secret_permissions = [
                "Get", "List",
            ]
        }
    }
}

variable "role_assignments" {
    default = {
        app_01_role_assignment = {
            scope = "acr_01"
            principal_id = "app_01"
            role_definition = "AcrPull"
        }
        app_02_role_assignment = {
            scope = "acr_01"
            principal_id = "app_02"
            role_definition = "AcrPull"
        }
    }
}


variable "acrs" {
    default = {
        acr_01 = {
            name = "coyhub"
            sku = "Premium"
            admin_enabled = false
            public_network_access_enabled = false
            network_rule_bypass_option = "None"
        }
    }
}

variable "private_dns_zones" {
    default = {
        private_dns_zone_acr = {
            virtual_network = "vnet_acr"
            link_name = "link-vnet-acr"
            dns_zone_name = "privatelink.azurecr.io"
        }
        private_dns_zone_app = {
            virtual_network = "vnet_app"
            link_name = "link-vnet-app"
            dns_zone_name = "privatelink.azurewebsites.net"
        }
        private_dns_zone_mysql = {
            virtual_network = "vnet_db"
            link_name = "link-vnet-db"
            dns_zone_name = "privatelink.mysql.database.azure.com"
        }
    }
}

variable "private_dns_zone_extra_links" {
    default = {
        private_dns_zone_acr_link_vnet_app = {
            link_name = "private-dns-zone-acr-link-vnet-app"
            virtual_network = "vnet_app"
            private_dns_zone = "private_dns_zone_acr"
        }
        private_dns_zone_acr_link_vnet_hub = {
            link_name = "private-dns-zone-acr-link-vnet-hub"
            virtual_network = "vnet_app"
            private_dns_zone = "private_dns_zone_acr"
        }
        private_dns_zone_mysql_link_vnet_app = {
            link_name = "private-dns-zone-mysql-link-vnet-app"
            virtual_network = "vnet_app"
            private_dns_zone = "private_dns_zone_mysql"
        }
        private_dns_zone_db_link_vnet_hub = {
            link_name = "private-dns-zone-mysql-link-vnet-hub"
            virtual_network = "vnet_hub"
            private_dns_zone = "private_dns_zone_mysql"
        }
    }
}

variable "private_endpoints" {
    default = {
        private_endpoint_acr = {
            attached_resource_name = "coyhub"
            private_dns_zone_ids = "private_dns_zone_acr"
            subresource_name = "registry"
            subnet = "vnet_acr_subnet_acr"
        }
        private_endpoint_app1 = {
            attached_resource_name = "app_service_01"
            private_dns_zone_ids = "private_dns_zone_app"
            subresource_name = "sites"
            subnet = "vnet_app_subnet_app1endpoint"
        }
        private_endpoint_app2 = {
            attached_resource_name = "app_service_02"
            private_dns_zone_ids = "private_dns_zone_app"
            subresource_name = "sites"
            subnet = "vnet_app_subnet_app2endpoint"
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
