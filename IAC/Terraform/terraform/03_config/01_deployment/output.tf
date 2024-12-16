output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
output "app_configuration_id" {
  value = azurerm_app_configuration.appconfig.id
}

output "app_configuration_name" {
  value = azurerm_app_configuration.appconfig.name
}
