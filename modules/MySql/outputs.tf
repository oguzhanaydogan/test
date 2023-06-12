output "name" {
    value = azurerm_mysql_flexible_server.mysql.name
}

output "id" {
    value = azurerm_mysql_flexible_server.mysql.id
}

output "host" {
    value = azurerm_mysql_flexible_server.mysql.fqdn  
}

output "database_name" {
    value = azurerm_mysql_flexible_database.db.name  
}

output "database_username" {
    value = azurerm_mysql_flexible_server.mysql.administrator_login
}

output "server_name" {
  value = azurerm_mysql_server.mysql.name
}