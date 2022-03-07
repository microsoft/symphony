/*
initialize the Azure environment. No remote storage, only performed once.
*/

provider "azurerm" {
  subscription_id = var.SUBSCRIPTION_ID
  # client_id       = "..."
  # client_secret   = "..."
  # tenant_id       = "..."
  features {} 
}
provider "azuread" {
  subscription_id = var.SUBSCRIPTION_ID
}

terraform {
  required_version = ">= v0.12.28"
}
