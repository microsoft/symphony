module "naming" {
  source = "git::https://github.com/Azure/terraform-azurerm-naming?ref=0.1.0"
  # levarage naming module.  Naming convention is resoure
  prefix = [ var.ENVIRONMENT ]
  suffix = [ var.NAME, "l03", "d01" ]
}

data "terraform_remote_state" "l02_d01" {
 backend = "azurerm"
 config = {
   resource_group_name  = var.BACKEND_RESOURCE_GROUP_NAME
   storage_account_name = var.BACKEND_STORAGE_ACCOUNT_NAME
   container_name = var.BACKEND_CONTAINER_NAME
   key = "02_sql/01_deployment"
 }
}

resource "null_resource" "configure_cs" {
    provisioner "local-exec" {
    command = "chmod +x setcs.sh && ./setcs.sh"

    environment = {
        CATALOGDBCS = data.terraform_remote_state.l02_d01.outputs.catalogdbcs
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

resource "azurerm_resource_group" "rg" {
  name     = module.naming.resource_group.name_unique
  location = var.LOCATION

  depends_on = [null_resource.configure_sql]
}

resource "azurerm_app_service_plan" "plan" {
  name                = var.APP_PLAN_NAME
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = var.PLAN_SKU_TIER
    size = var.PLAN_SKU_SIZE
  }
}

resource "azurerm_app_service" "app" {
  name                = var.APP_NAME
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
    linux_fx_version = "DOCKER|${var.DOCKER_IMAGE_NAME}"
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT" = "Docker"
    "ASPNETCORE_URL" = "http://+:80"
    "ConnectionStrings__CatalogConnection" = data.terraform_remote_state.l02_d01.outputs.catalogdbcs
    "ConnectionStrings__IdentityConnection" = data.terraform_remote_state.l02_d01.outputs.identitydbcs
  }
}