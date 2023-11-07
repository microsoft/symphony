# ------------------------------------------------------------------------------------------------------
# DEPLOY  a reources group, sql server, sql database and firewall rules - Uses Remote state
# ------------------------------------------------------------------------------------------------------


resource "random_string" "sqlserverlogin" {
  length  = 10
  special = false
  numeric = false
}

resource "random_password" "sqlserverpassword" {
  length           = 16
  special          = true
  override_special = "#()-[]<>^*&#$"
}

# ------------------------------------------------------------------------------------------------------
# Deploy resource Group
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "rg_name" {
  name          = "sql"
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
# Deploy sql server
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "sqlserver_name" {
  name          = "sqlserver"
  resource_type = "azurerm_sql_server"
  prefixes      = [var.env]
  random_length = 3
  clean_input   = true
}
resource "azurerm_sql_server" "sqlserver" {
  name                         = azurecaf_name.sqlserver_name.result
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = random_string.sqlserverlogin.result
  administrator_login_password = random_password.sqlserverpassword.result
  tags                         = { env : var.env }
}

resource "azurerm_sql_firewall_rule" "fw" {
  name                = "FirewallRule1"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.sqlserver.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# ------------------------------------------------------------------------------------------------------
# Deploy sql databases
# ------------------------------------------------------------------------------------------------------
resource "azurerm_sql_database" "catalogdb" {
  name                = "catalogdb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.sqlserver.name
  edition             = "Basic"
  tags                = { env : var.env }
}

resource "azurerm_sql_database" "identitydb" {
  name                = "identitydb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.sqlserver.name
  edition             = "Basic"
  tags                = { env : var.env }
}
