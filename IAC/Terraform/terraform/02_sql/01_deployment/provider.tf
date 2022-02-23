###########################################################################################################
# PROVIDERS
###########################################################################################################

# Configure the Azure Provider
terraform {
  required_version = "= v1.0.10"
  backend "azurerm" {}
  required_providers {
    azurerm = {
      version = "~>2.85.0"
      source  = "hashicorp/azurerm"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.1.3"
    }
  }
}

provider "azurerm" {
  features {}
}

