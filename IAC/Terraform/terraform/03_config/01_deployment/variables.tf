variable "location" {
  description = "The supported azure location where the resource deployed"
  type        = string
}

variable "env" {
  description = "The name of the environment to be deployed"
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
