output "name" {
  value = azurerm_container_registry.acr.name
}

output "id" {
  value = azurerm_container_registry.acr.id 
}

output "fqdn" {
  value = azurerm_container_registry.acr.login_server
  
}