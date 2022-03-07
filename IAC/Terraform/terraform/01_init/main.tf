resource "azurerm_resource_group" "tfstate_rg" {
  name     = var.BACKEND_RESOURCE_GROUP_NAME
  location = var.LOCATION
}

resource "azurerm_storage_account" "tfstate" {
  name                     = var.BACKEND_STORAGE_ACCOUNT_NAME # globally unique
  resource_group_name      = azurerm_resource_group.tfstate_rg.name
  location                 = azurerm_resource_group.tfstate_rg.location
  account_tier             = var.STORAGE_ACCOUNT_ACCOUNT_TIER
  account_replication_type = var.STORAGE_ACCOUNT_ACCOUNT_REPLICATION_TYPE # LRS, GRS, RAGRS, ZRS
  account_kind             = var.STORAGE_ACCOUNT_ACCOUNT_KIND

  identity {
    type = var.IDENTITY_TYPE
  }

  tags = {
    environment = var.TAGS_ENVIRONMENT
    version     = var.TAGS_VERSION
  }
}


### TF State Container for Terraform###

resource "azurerm_storage_container" "tfstate_container" {
  name                  = var.BACKEND_CONTAINER_NAME
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

### BAK

resource "azurerm_resource_group" "tfstatebak_rg" {
  name     = var.BACKEND_BACKUP_RESOURCE_GROUP_NAME
  location = var.LOCATION
}

resource "azurerm_storage_account" "tfstatebak" {
  name                     = var.BACKUP_STORAGE_ACCOUNT_NAME
  resource_group_name      = azurerm_resource_group.tfstatebak_rg.name
  location                 = azurerm_resource_group.tfstatebak_rg.location
  account_tier             = var.STORAGE_ACCOUNT_ACCOUNT_TIER
  account_replication_type = var.STORAGE_ACCOUNT_ACCOUNT_REPLICATION_TYPE # LRS, GRS, RAGRS, ZRS
  account_kind             = var.STORAGE_ACCOUNT_ACCOUNT_KIND

  identity {
    type = var.IDENTITY_TYPE
  }

  tags = {
    environment = var.TAGS_ENVIRONMENT
    version     = var.TAGS_VERSION
  }
}
