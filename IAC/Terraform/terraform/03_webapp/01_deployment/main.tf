data "terraform_remote_state" "l02_d01" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.rs_resource_group_name
    storage_account_name = var.rs_storage_account_name
    container_name       = var.rs_container_name
    key                  = var.rs_container_key #"02_sql/01_deployment"
  }
}

resource "null_resource" "configure_cs" {
  provisioner "local-exec" {
    command = "chmod +x setcs.sh && ./setcs.sh"

    environment = {
      CATALOGDBCS  = data.terraform_remote_state.l02_d01.outputs.catalogdbcs
      IDENTITYDBCS = data.terraform_remote_state.l02_d01.outputs.identitydbcs
    }
  }
}

resource "null_resource" "configure_sql" {
  provisioner "local-exec" {
    command = "chmod +x setupdb.sh && ./setupdb.sh"
  }
  depends_on = [null_resource.configure_cs]
}

# ------------------------------------------------------------------------------------------------------
# Deploy resource group
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "rg_name" {
  name          = "rg-web"
  resource_type = "azurerm_resource_group"
  prefixes      = [var.env]
  random_length = 3
  clean_input   = true
}
resource "azurerm_resource_group" "rg" {
  name     = azurecaf_name.rg_name.result
  location = var.location

  depends_on = [null_resource.configure_sql]
}

# ------------------------------------------------------------------------------------------------------
# Deploy app service plan
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "app_svc_plan" {
  name          = "app-svc-plan"
  resource_type = "azurerm_app_service"
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
  name          = "app-svc"
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
    linux_fx_version = "DOCKER|${var.docker_image_name}"
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT"                = "Docker"
    "ASPNETCORE_URL"                        = "http://+:80"
    "ConnectionStrings__CatalogConnection"  = data.terraform_remote_state.l02_d01.outputs.catalogdbcs
    "ConnectionStrings__IdentityConnection" = data.terraform_remote_state.l02_d01.outputs.identitydbcs
  }
}