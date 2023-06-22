resource "azurerm_container_registry" "acr" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  admin_enabled                 = var.admin_enabled
  sku                           = var.sku
  public_network_access_enabled = var.public_network_access_enabled
  network_rule_bypass_option    = var.network_rule_bypass_option
}