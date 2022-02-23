/*
initialize the Azure environment. No remote storage, only performed once.
*/

#Set the terraform required version, and Configure the Azure Provider
terraform {
  required_version = "= v1.0.10"
  required_providers {
    azurerm = {
      version = "~>2.85.0"
      source  = "hashicorp/azurerm"
    }
    azuread = {
      version = "=0.7"
    }
  }
}

provider "azurerm" {
  features {}
}