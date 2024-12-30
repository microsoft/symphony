//go:build e2e_test
// +build e2e_test

package terraform

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func Test_EndToEnd(t *testing.T) {
	t.Parallel()

	//load remote state env vars
	rmResourceGroupName := os.Getenv("resource_group_name")
	rmStorageAccName := os.Getenv("storage_account_name")
	rmContainerName := os.Getenv("container_name")
	envName := os.Getenv("ENVIRONMENT_NAME") + "/"

	// Configure Terraform setting up a path to Terraform code.
	terraformOptions02 := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../terraform/02_storage/01_deployment",

		// Variables to pass to init remote state
		BackendConfig: map[string]interface{}{
			"resource_group_name":  rmResourceGroupName,
			"container_name":       rmContainerName,
			"storage_account_name": rmStorageAccName,
			"key":                  envName + "02_storage/01_deployment.tfstate"},
		Reconfigure: true,
	}
	terraformOptions03 := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../terraform/03_config/01_deployment",

		// Variables to pass to init remote state
		BackendConfig: map[string]interface{}{
			"resource_group_name":  rmResourceGroupName,
			"container_name":       rmContainerName,
			"storage_account_name": rmStorageAccName,
			"key":                  envName + "03_config/01_deployment.tfstate"},
		Reconfigure: true,
	}

	//Run `terraform init` to init remote state.
	terraform.InitE(t, terraformOptions02)
	terraform.InitE(t, terraformOptions03)

	// Run `terraform output` to get the values of output variables from the terraform.tfstate
	resourceGroupName := terraform.Output(t, terraformOptions02, "resource_group_name")
	storageAccountName := terraform.Output(t, terraformOptions02, "storage_account_name")
	configResourceGroupName := terraform.Output(t, terraformOptions03, "resource_group_name")
	configId := terraform.Output(t, terraformOptions03, "app_configuration_id")
	configName := terraform.Output(t, terraformOptions03, "app_configuration_name")

	// Check that the output values are not empty
	assert.NotEmpty(t, resourceGroupName, "Resource Group Name is empty")
	assert.NotEmpty(t, storageAccountName, "Storage Account Name is empty")
	assert.NotEmpty(t, configResourceGroupName, "Config Resource Group Name is empty")
	assert.NotEmpty(t, configId, "App Configuration ID is empty")
	assert.NotEmpty(t, configName, "App Configuration Name is empty")
}
