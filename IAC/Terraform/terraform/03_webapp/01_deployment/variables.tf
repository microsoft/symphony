variable "location" {
  description = "The supported azure location where the resource deployed"
}

variable "env" {
  description = "The name of the evnironemnt to be deployed"
}

variable "docker_image_name" {
  description = "The url to the app docker image"
}

variable "docker_image_tag" {
  description = "The url to the app docker image"
}

variable "cr_resource_group_name" {
  description = "Container Registry Resource Group Name"
}

variable "cr_name" {
  description = "Container Registry Name"
}

variable "app_service_sku_size" {
  description = "Ther SKU Size for the app service"
}

variable "app_service_sku_tier" {
  description = "Ther SKU TIER for the app service"
}

variable "rs_resource_group_name" {
  description = "The name of the remote state resource group"
}

variable "rs_storage_account_name" {
  description = "The name of the remote state storage account"
}

variable "rs_container_name" {
  description = "The name of the remote state storage account container"
}

variable "rs_container_key" {
  description = "The name of the remote state file in the storage account container"
}

