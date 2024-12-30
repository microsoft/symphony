//go:build 03_config || module_test
// +build 03_config module_test

package terraform

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func Test03_Config(t *testing.T) {
	t.Parallel()

	//load remote state env vars
	rmResourceGroupName := os.Getenv("resource_group_name")
	rmStorageAccName := os.Getenv("storage_account_name")
	rmContainerName := os.Getenv("container_name")
	rmKey := "03_config/01_deployment_test.tfstate"

	// Configure Terraform setting up a path to Terraform code.
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../terraform/03_config/01_deployment",

		// Variables to pass to init remote state
		BackendConfig: map[string]interface{}{
			"resource_group_name":  rmResourceGroupName,
			"container_name":       rmContainerName,
			"storage_account_name": rmStorageAccName,
			"key":                  rmKey},
		Vars: map[string]interface{}{
			"rs_container_key": "Test_Mocks/02_storage/01_deployment.tfstate",
		},
		Reconfigure: true,
	}

	// Defer 'terraform Destroy'
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` to init remote state.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables from the terraform.tfstate
	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
	appConfigId := terraform.Output(t, terraformOptions, "app_configuration_id")
	appConfigName := terraform.Output(t, terraformOptions, "app_configuration_name")

	// Assert output values are not empty
	assert.NotEmpty(t, resourceGroupName, "Resource Group Name is empty")
	assert.NotEmpty(t, appConfigId, "App Configuration ID is empty")
	assert.NotEmpty(t, appConfigName, "App Configuration Name is empty")
}
