output "name" {
    value = azurerm_mysql_server.mysql.name
}

output "id" {
    value = azurerm_mysql_server.mysql.id
}

output "host" {
    value = azurerm_mysql_server.mysql.fqdn  
}

output "database_name" {
    value = azurerm_mysql_database.db.name  
}

output "database_username" {
    value = azurerm_mysql_server.mysql.administrator_login
}