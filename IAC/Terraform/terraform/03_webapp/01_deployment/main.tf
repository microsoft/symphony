data "terraform_remote_state" "l02_d01" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.rs_resource_group_name
    storage_account_name = var.rs_storage_account_name
    container_name       = var.rs_container_name
    key                  = strcontains(var.rs_container_key, "Test_Mocks") ? var.rs_container_key : "${var.env}/${var.rs_container_key}" #"02_sql/01_deployment"
  }
}

# ------------------------------------------------------------------------------------------------------
# Deploy resource group
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "rg_name" {
  name          = "web"
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

# ------------------------------------------------------------------------------------------------------
# Deploy app service plan
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "app_svc_plan" {
  name          = "app-svc"
  resource_type = "azurerm_app_service_plan"
  prefixes      = [var.env]
  random_length = 3
  clean_input   = true
}
resource "azurerm_app_service_plan" "plan" {
  name                = azurecaf_name.app_svc_plan.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = var.app_service_sku_tier
    size = var.app_service_sku_size
  }
}

# ------------------------------------------------------------------------------------------------------
# Deploy app service
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "app_svc" {
  name          = "web"
  resource_type = "azurerm_app_service"
  prefixes      = [var.env]
  random_length = 3
  clean_input   = true
}
resource "azurerm_app_service" "app" {
  name                = azurecaf_name.app_svc.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
    acr_use_managed_identity_credentials = true
    linux_fx_version                     = "DOCKER|${var.docker_image_name_web}:${var.docker_image_tag}"
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT"                = "Docker"
    "ASPNETCORE_URL"                        = "http://+:80"
    "ConnectionStrings__CatalogConnection"  = data.terraform_remote_state.l02_d01.outputs.catalogdbcs
    "ConnectionStrings__IdentityConnection" = data.terraform_remote_state.l02_d01.outputs.identitydbcs
  }
}

resource "azurerm_role_assignment" "cr_role_assignment" {
  scope                = data.azurerm_container_registry.cr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_app_service.app.identity[0].principal_id
}

data "azurerm_container_registry" "cr" {
  name                = var.cr_name
  resource_group_name = var.cr_resource_group_name
}
