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
  required_version = ">= 1.1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.98.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.18.0"
    }
  }
}
