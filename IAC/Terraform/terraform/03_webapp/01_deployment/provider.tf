#Set the terraform required version, and Configure the Azure Provider.Use remote storage

# Configure the Azure Provider
terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  backend "azurerm" {}
  required_providers {
    azurerm = {
      version = "~>2.98.0"
      source  = "hashicorp/azurerm"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.15"
    }
  }
}

provider "azurerm" {
  features {}
}
