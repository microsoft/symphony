# ------------------------------------------------------------------------------------------------------
# DEPLOY  a reources group and a storage account - Uses Remote state
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
# Deploy resource Group
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "rg_name" {
  name          = "storage"
  resource_type = "azurerm_resource_group"
  prefixes      = [var.env]
  random_length = 3
  clean_input   = true
}
resource "azurerm_resource_group" "rg" {
  name     = azurecaf_name.rg_name.result
  location = var.location

  tags = {
    env         = var.env,
    GeneratedBy = "symphony"
  }
}

# ------------------------------------------------------------------------------------------------------
# Deploy storage account
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "storage_name" {
  name          = "storage"
  resource_type = "azurerm_storage_account"
  prefixes      = [var.env]
  random_length = 3
  clean_input   = true
}
resource "azurerm_storage_account" "storage" {
  name                     = azurecaf_name.storage_name.result
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = { env : var.env }
}
