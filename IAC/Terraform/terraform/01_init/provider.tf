/*
initialize the Azure environment. No remote storage, only performed once.
*/

#Set the terraform required version, and Configure the Azure Provider
terraform {
  required_version = ">= 1.6.2, < 2.0.0"
  required_providers {
    azurerm = {
      version = "~>2.98.0"
      source  = "hashicorp/azurerm"
    }
    azuread = {
      version = "~>2.18.0"
    }
  }
}

provider "azurerm" {
  features {}
}
