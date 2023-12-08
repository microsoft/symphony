variable "location" {
  description = "The supported azure location where the resource deployed"
  type        = string
}

variable "env" {
  description = "The name of the environment to be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "the name of the AzureRm backend resource group"
  type        = string
}
variable "storage_account_name" {
  description = "the name of the AzureRm backend storage account"
  type        = string
}

variable "storage_account_tier" {
  description = "the tier of the AzureRm backend storage account"
  type        = string
}

variable "storage_account_replication_type" {
  description = "the replication type of the AzureRm backend storage account e.g. LRS, ZRS,GRS"
  type        = string
}

variable "storage_account_kind" {
  description = "the kind type of the AzureRm backend storage account e.g. BlobStorage, BlockBlobStorage, StorageV2"
  type        = string
}

variable "identity_type" {
  description = "storage account identity type e.g. SystemAssigned"
  type        = string
}

variable "container_name" {
  description = "the name of the AzureRm backend storage account container"
  type        = string
}

variable "backup_resource_group_name" {
  description = "the name of the AzureRm backend backup resource group"
  type        = string
}

variable "backup_storage_account_name" {
  description = "the name of the AzureRm backend backup storage account"
  type        = string
}

variable "env_version" {
  description = "The version of the environment to be deployed"
  type        = string
}
