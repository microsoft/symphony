// +build 01_init

package terraform

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/stretchr/testify/assert"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func Test01_Init_Storage(t *testing.T) {
	t.Parallel()
	// Configure Terraform setting up a path to Terraform code.
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../terraform/01_init",
	}

	// Defer 'terraform Destroy'
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` to init remote state.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables from the terraform.tfstate
	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
	storageAccountName := terraform.Output(t, terraformOptions, "storage_account_name")
	containerName := terraform.Output(t, terraformOptions, "Container_name")

	bkResourceGroupName := terraform.Output(t, terraformOptions, "backup_resource_group_name")
	bkStorageAccoutName := terraform.Output(t, terraformOptions, "backup_storage_account_name")

	// assert the resource group, storage account, and container exists
	assert.True(t, azure.ResourceGroupExists(t, resourceGroupName, ""), "Primary Resource group does not exist")
	assert.True(t, azure.StorageAccountExists(t, storageAccountName, resourceGroupName, ""), "Storage Account does not exist")
	assert.True(t, azure.StorageBlobContainerExists(t, containerName, storageAccountName, resourceGroupName, ""), "Container deos not exist")

	assert.True(t, azure.ResourceGroupExists(t, bkResourceGroupName, ""), "Backup Resource group does not exist")
	assert.True(t, azure.StorageAccountExists(t, bkStorageAccoutName, bkResourceGroupName, ""), "Backup Storage Account does not exist")
}
