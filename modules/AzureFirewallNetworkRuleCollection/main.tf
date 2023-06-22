resource "azurerm_firewall_network_rule_collection" "example" {
  name                = var.name
  azure_firewall_name = var.firewall
  resource_group_name = var.resource_group_name
  priority            = var.priority
  action              = var.action

   dynamic "rule" {
    for_each = var.network_firewall_rules
    content {
        name = rule.key
        source_addresses = rule.value.source_addresses
        destination_ports = rule.value.destination_ports
        destination_addresses = rule.value.destination_addresses
        protocols = rule.value.protocols
    }    
  }
}