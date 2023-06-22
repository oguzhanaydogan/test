data "azurerm_key_vault" "example" {
  name                = var.key_vault
  resource_group_name = var.key_vault_resource_group
}

data "azurerm_key_vault_secret" "secret" {
  name         = var.secret
  key_vault_id = data.azurerm_key_vault.example.id
}
