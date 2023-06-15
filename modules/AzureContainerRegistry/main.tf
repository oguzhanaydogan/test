resource "azurerm_container_registry" "acr" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  admin_enabled                 = false
  sku                           = "Premium"
  public_network_access_enabled = false
  network_rule_bypass_option    = "None"
}