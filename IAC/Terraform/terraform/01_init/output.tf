output "resource_group_name" {
  value = azurerm_resource_group.tfstate_rg.name
}
output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}
output "container_name" {
  value = azurerm_storage_container.tfstate_container.name
}
output "backup_resource_group_name" {
  value = azurerm_resource_group.tfstatebak_rg.name
}
output "backup_storage_account_name" {
  value = azurerm_storage_account.tfstatebak.name
}
