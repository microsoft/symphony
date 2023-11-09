output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
output "sql_server_name" {
  value = azurerm_sql_server.sqlserver.name
}

output "catalog_sql_db_name" {
  value = azurerm_sql_database.catalogdb.name
}

output "identity_sql_db_name" {
  value = azurerm_sql_database.identitydb.name
}

output "catalogdbcs" {
  sensitive = true
  value     = "Server=tcp:${azurerm_sql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_sql_database.catalogdb.name};Persist Security Info=False;User ID=${random_string.sqlserverlogin.result};Password=${random_password.sqlserverpassword.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

output "identitydbcs" {
  sensitive = true
  value     = "Server=tcp:${azurerm_sql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_sql_database.identitydb.name};Persist Security Info=False;User ID=${random_string.sqlserverlogin.result};Password=${random_password.sqlserverpassword.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}
