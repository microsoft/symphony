resource "random_string" "sqlserverlogin" {
  length  = 10
  special = false
  number  = false
}

resource "random_password" "sqlserverpassword" {
  length           = 16
  special          = true
  override_special = "#()-[]<>^*&#$"
}

module "naming" {
  source = "git::https://github.com/Azure/terraform-azurerm-naming?ref=0.1.0"
  # levarage naming module. Naming convention is resoure
  prefix = [var.ENVIRONMENT]
  suffix = [var.NAME, "l02", "d01"]
}

resource "azurerm_resource_group" "rg" {
  name     = module.naming.resource_group.name_unique
  location = var.LOCATION
}

resource "azurerm_sql_server" "sqlserver" {
  name                         = module.naming.sql_server.name_unique
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = random_string.sqlserverlogin.result
  administrator_login_password = random_password.sqlserverpassword.result
}

resource "azurerm_sql_firewall_rule" "fw" {
  name                = "FirewallRule1"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.sqlserver.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_sql_database" "catalogdb" {
  name                = "catalogdb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.sqlserver.name
  edition             = "Basic"
}

resource "azurerm_sql_database" "identitydb" {
  name                = "identitydb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.sqlserver.name
  edition             = "Basic"
}
