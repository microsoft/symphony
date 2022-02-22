/*
initialize the Azure environment. No remote storage, only performed once.
*/

provider "azurerm" {
  subscription_id = var.SUBSCRIPTION_ID
  # client_id       = "..."
  # client_secret   = "..."
  # tenant_id       = "..."
  version           = "~>2.85.0"
  features {} 
}
provider "azuread" {
  version         = "=0.7" 
  subscription_id = var.SUBSCRIPTION_ID
}

terraform {
  required_version = "= v1.0.10"
}
