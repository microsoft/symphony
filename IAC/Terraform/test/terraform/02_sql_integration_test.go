package terraform

import (
	"os"
	"testing"

	"github.com/Azure/azure-sdk-for-go/services/sql/mgmt/2014-04-01/sql"
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func Test02_SQL(t *testing.T) {
	t.Parallel()

	//load remote state env vars
	rmResourceGroupName := os.Getenv("resource_group_name")
	rmStorageAccName := os.Getenv("storage_account_name")
	rmContainerName := os.Getenv("container_name")
	rmKey := os.Getenv("key")

	// Configure Terraform setting up a path to Terraform code.
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../terraform/02_sql/01_deployment",

		// Variables to pass to init remote state
		BackendConfig: map[string]interface{}{
			"resource_group_name":  rmResourceGroupName,
			"container_name":       rmContainerName,
			"storage_account_name": rmStorageAccName,
			"key":                  rmKey},
	}
	//Run `terraform init` to init remote state.
	terraform.InitE(t, terraformOptions)

	// Run `terraform output` to get the values of output variables from the terraform.tfstate
	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
	sqlServerName := terraform.Output(t, terraformOptions, "sql_server_name")

	catalogDBName := terraform.Output(t, terraformOptions, "catalog_sql_db_name")
	identityDBName := terraform.Output(t, terraformOptions, "identity_sql_db_name")
	expectedSQLDBStatus := "Online"

	// assert deployed server and databases status
	assert.Equal(t, sql.ServerStateReady, azure.GetSQLServer(t, resourceGroupName, sqlServerName, ""), "SQl server Status")
	assert.Equal(t, expectedSQLDBStatus, *azure.GetSQLDatabase(t, resourceGroupName, sqlServerName, catalogDBName, "").Status, "Catalog SQL DB Status")
	assert.Equal(t, expectedSQLDBStatus, *azure.GetSQLDatabase(t, resourceGroupName, sqlServerName, identityDBName, "").Status, "Identity SQL DB Status")

}
