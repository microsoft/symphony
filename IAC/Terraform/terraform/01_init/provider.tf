/*
initialize the Azure environment. No remote storage, only performed once.
*/

#Set the terraform required version, and Configure the Azure Provider
terraform {
  required_version = "= v1.1.7"
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