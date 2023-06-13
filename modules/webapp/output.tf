output "id" {
    value = azurerm_linux_web_app.webapp.id
}

output "name" {
    value = azurerm_linux_web_app.webapp.name
}

output "key_vault_reference_identity_id" {
    value = azurerm_linux_web_app.webapp.identity[0].principal_id
}

output "fqdn" {
    value = azurerm_linux_web_app.webapp.default_hostname
}

