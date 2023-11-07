# ------------------------------------------------------------------------------------------------------
# DEPLOY  primary and backup reources group, storage accounts, and containers for Remote state
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
# Deploy primary resource Group
# ------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "tfstate_rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    GeneratedBy = "symphony"
  }
}

# ------------------------------------------------------------------------------------------------------
# Deploy primary Storage Account
# ------------------------------------------------------------------------------------------------------
resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name # globally unique
  resource_group_name      = azurerm_resource_group.tfstate_rg.name
  location                 = azurerm_resource_group.tfstate_rg.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type # LRS, GRS, RAGRS, ZRS
  account_kind             = var.storage_account_kind

  identity {
    type = var.identity_type
  }

  tags = {
    env     = var.env
    version = var.env_version
  }
}

# ------------------------------------------------------------------------------------------------------
# Deploy primary Storage Account Container
# ------------------------------------------------------------------------------------------------------
resource "azurerm_storage_container" "tfstate_container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# ------------------------------------------------------------------------------------------------------
# Deploy backup resource Group
# ------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "tfstatebak_rg" {
  name     = var.backup_resource_group_name
  location = var.location
  tags = {
    GeneratedBy = "symphony"
  }
}

# ------------------------------------------------------------------------------------------------------
# Deploy backup Storage Account
# ------------------------------------------------------------------------------------------------------
resource "azurerm_storage_account" "tfstatebak" {
  name                     = var.backup_storage_account_name
  resource_group_name      = azurerm_resource_group.tfstatebak_rg.name
  location                 = azurerm_resource_group.tfstatebak_rg.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  account_kind             = var.storage_account_kind

  identity {
    type = var.identity_type
  }

  tags = {
    env     = var.env
    version = var.env_version
  }
}
