resource "azurerm_mysql_server" "mysql" {
  name                = var.server_name
  location            = var.location
  resource_group_name = var.resourcegroup

  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password

  sku_name   = "GP_Gen5_2"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = true
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = false
  ssl_enforcement_enabled           = false
  ssl_minimal_tls_version_enforced  = "TLSEnforcementDisabled"
}

resource "azurerm_mysql_database" "db" {
  name                = var.db_name
  resource_group_name = var.resourcegroup
  server_name         = azurerm_mysql_server.mysql.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}