//go:build 02_storage || module_test
// +build 02_storage module_test

package terraform

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func Test02_Storage(t *testing.T) {
	t.Parallel()

	location := "westus"
	env := "dev"
	//load remote state env vars
	rmResourceGroupName := os.Getenv("resource_group_name")
	rmStorageAccName := os.Getenv("storage_account_name")
	rmContainerName := os.Getenv("container_name")
	rmKey := "02_storage/01_deployment_test.tfstate"

	// Configure Terraform setting up a path to Terraform code.
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../terraform/02_storage/01_deployment",

		// Variables to pass to init remote state
		BackendConfig: map[string]interface{}{
			"resource_group_name":  rmResourceGroupName,
			"container_name":       rmContainerName,
			"storage_account_name": rmStorageAccName,
			"key":                  rmKey},

		Vars: map[string]interface{}{
			"location": location,
			"env":      env,
		},
		Reconfigure: true,
	}

	// Defer 'terraform Destroy'
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` to init remote state.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables from the terraform.tfstate
	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
	storageAccountName := terraform.Output(t, terraformOptions, "storage_account_name")

	// Assert deployed server and databases status
	assert.NotEmpty(t, resourceGroupName, "Resource Group Name is empty")
	assert.NotEmpty(t, storageAccountName, "Storage Account Name is empty")
}
