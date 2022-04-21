variable "location" {
  description = "The supported azure location where the resource deployed"
}

variable "env" {
  description = "The name of the evnironemnt to be deployed"
}

variable "resource_group_name" {
  description = "the name of the AzureRm backend resource group"
}
variable "storage_account_name" {
  description = "the name of the AzureRm backend storage account"
}

variable "storage_account_tier" {
  description = "the tier of the AzureRm backend storage account"
}

variable "storage_account_replication_type" {
  description = "the replication type of the AzureRm backend storage account e.g. LRS, ZRS,GRS"
}

variable "storage_account_kind" {
  description = "the kind type of the AzureRm backend storage account e.g. BlobStorage, BlockBlobStorage, StorageV2"
}

variable "identity_type" {
  description = "storage account identity type e.g. SystemAssigned "
}
variable "container_name" {
  description = "the name of the AzureRm backend storage account container"
}

variable "backup_resource_group_name" {
  description = "the name of the AzureRm backend backup resource group"
}
variable "backup_storage_account_name" {
  description = "the name of the AzureRm backend backup storage account"
}

variable "env_version" {
  description = "The version of the evnironemnt to be deployed"
}
