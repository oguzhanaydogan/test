resource "azurerm_linux_web_app" "webapp" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.service_plan_id
  key_vault_reference_identity_id = azurerm_linux_web_app.webapp.identity[0].principal_id
  site_config {}
  identity {
    type = "SystemAssigned"
  }
}