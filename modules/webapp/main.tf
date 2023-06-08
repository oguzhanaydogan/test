resource "azurerm_linux_web_app" "webapp" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.service_plan_id
  site_config {}
  identity {
    type = "SystemAssigned"
  }
  app_settings = var.app_settings
}