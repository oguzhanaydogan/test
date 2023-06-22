output "id" {  
    value = data.azurerm_key_vault_secret.secret.id
}

output "value" {
    value = data.azurerm_key_vault_secret.secret.value
}



