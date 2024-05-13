variable "location" {
  description = "The supported azure location where the resource deployed"
  type        = string
}

variable "env" {
  description = "The name of the environment to be deployed"
  type        = string
}

variable "docker_image_name_web" {
  description = "The url to the app docker image"
  type        = string
}

variable "docker_image_tag" {
  description = "The url to the app docker image"
  type        = string
}

variable "cr_resource_group_name" {
  description = "Container Registry Resource Group Name"
  type        = string
}

variable "cr_name" {
  description = "Container Registry Name"
  type        = string
}

variable "app_service_sku_size" {
  description = "Ther SKU Size for the app service"
  type        = string
}

variable "app_service_sku_tier" {
  description = "Ther SKU TIER for the app service"
  type        = string
}

variable "rs_resource_group_name" {
  description = "The name of the remote state resource group"
  type        = string
}

variable "rs_storage_account_name" {
  description = "The name of the remote state storage account"
  type        = string
}

variable "rs_container_name" {
  description = "The name of the remote state storage account container"
  type        = string
}

variable "rs_container_key" {
  description = "The name of the remote state file in the storage account container"
  type        = string
}
