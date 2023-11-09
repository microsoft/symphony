output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
output "app_service_id" {
  value = azurerm_app_service.app.id
}

output "app_service_name" {
  value = azurerm_app_service.app.name
}

output "default_hostname" {
  value = azurerm_app_service.app.default_site_hostname
}
