resource "azurerm_linux_web_app" "webapp" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.service_plan_id
  app_settings        = var.app_settings
  
  lifecycle {
    ignore_changes = [virtual_network_subnet_id]
  }
  site_config {
    application_stack {
      docker_image = var.image_name
      docker_image_tag = var.image_tag
    }
  }
  identity {
    type = "SystemAssigned"
  }
}