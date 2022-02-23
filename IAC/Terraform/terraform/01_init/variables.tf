variable "location" {
  description = "The supported azure location where the resource deployed"
}

variable "env" {
  description = "The name of the evnironemnt to be deployed"
}

variable "resource_group_name" {
  description = "the name of the AZurerm backend resource group"
}
variable "storage_account_name" {
  description = "the name of the AZurerm backend storage account"
}

variable "storage_account_tier" {
  description = "the tier of the AZurerm backend storage account"
}

variable "storage_account_replication_type" {
  description = "the replication type of the AZurerm backend storage account e.g. LRS, ZRS,GRS"
}

variable "storage_account_kind" {
  description = "the kind type of the AZurerm backend storage account e.g. BlobStorage, BlockBlobStorage, StorageV2"
}

variable "identity_type" {
  description = "storage account identity type e.g. SystemAssigned "
}
variable "Container_name" {
  description = "the name of the AZurerm backend storage account container"
}

variable "backup_resource_group_name" {
  description = "the name of the AZurerm backend backup resource group"
}
variable "backup_storage_account_name" {
  description = "the name of the AZurerm backend backup storage account"
}

variable "env_version" {
    description = "The version of the evnironemnt to be deployed"
}
/*variable "SUBSCRIPTION_ID" {}
variable "LOCATION" {}


variable "STORAGE_ACCOUNT_ACCOUNT_TIER" {} # 
variable "STORAGE_ACCOUNT_ACCOUNT_REPLICATION_TYPE" {} #
variable "STORAGE_ACCOUNT_ACCOUNT_KIND" {} #
variable "IDENTITY_TYPE" {}
variable "TAGS_ENVIRONMENT" {}
variable "TAGS_VERSION" {}
variable "ENVIRONMENT" {} #
variable "BACKEND_STORAGE_ACCOUNT_NAME" {} #
variable "BACKEND_CONTAINER_NAME" {} #
variable "BACKEND_RESOURCE_GROUP_NAME" {}  #
variable "BACKEND_BACKUP_RESOURCE_GROUP_NAME" {} #
variable "BACKUP_STORAGE_ACCOUNT_NAME" {}*/ #