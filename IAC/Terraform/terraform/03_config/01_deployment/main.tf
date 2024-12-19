data "terraform_remote_state" "l02_d01" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.rs_resource_group_name
    storage_account_name = var.rs_storage_account_name
    container_name       = var.rs_container_name
    key                  = strcontains(var.rs_container_key, "Test_Mocks") ? var.rs_container_key : "${var.env}/${var.rs_container_key}" #"02_storage/01_deployment"
  }
}

# ------------------------------------------------------------------------------------------------------
# Deploy resource group
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "rg_name" {
  name          = "config"
  resource_type = "azurerm_resource_group"
  prefixes      = [var.env]
  random_length = 3
  clean_input   = true
}

resource "azurerm_resource_group" "rg" {
  name     = azurecaf_name.rg_name.result
  location = var.location
  tags = {
    GeneratedBy = "symphony"
  }
}

data "azurerm_client_config" "client_config" {
}

resource "azurerm_role_assignment" "data_owner_role_assignment" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_client_config.client_config.object_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy app configuration
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "app_configuration" {
  name          = "appconfig"
  resource_type = "azurerm_app_configuration"
  prefixes      = [var.env]
  random_length = 3
  clean_input   = true
}
resource "azurerm_app_configuration" "appconfig" {
  name                = azurecaf_name.app_configuration.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "standard"

  depends_on = [
    azurerm_role_assignment.data_owner_role_assignment
  ]
}

# ------------------------------------------------------------------------------------------------------
# Deploy app config key
# ------------------------------------------------------------------------------------------------------

resource "azurerm_app_configuration_key" "app_config_key" {
  configuration_store_id = azurerm_app_configuration.appconfig.id
  key                    = "storageAccountName"
  value                  = data.terraform_remote_state.l02_d01.outputs.storage_account_name
  content_type           = "text/plain"
}
