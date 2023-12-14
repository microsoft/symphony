//go:build e2e_test
// +build e2e_test

package terraform

import (
  "crypto/tls"
  "os"
  "testing"

  "github.com/Azure/azure-sdk-for-go/services/sql/mgmt/2014-04-01/sql"
  "github.com/gruntwork-io/terratest/modules/azure"
  http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
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
  terraformOptions_02 := &terraform.Options{
    // The path to where our Terraform code is located
    TerraformDir: "../../terraform/02_sql/01_deployment",

    // Variables to pass to init remote state
    BackendConfig: map[string]interface{}{
      "resource_group_name":  rmResourceGroupName,
      "container_name":       rmContainerName,
      "storage_account_name": rmStorageAccName,
      "key":                  envName + "02_sql/01_deployment.tfstate"},
    Reconfigure: true,
  }
  terraformOptions_03 := &terraform.Options{
    // The path to where our Terraform code is located
    TerraformDir: "../../terraform/03_webapp/01_deployment",

    // Variables to pass to init remote state
    BackendConfig: map[string]interface{}{
      "resource_group_name":  rmResourceGroupName,
      "container_name":       rmContainerName,
      "storage_account_name": rmStorageAccName,
      "key":                  envName + "03_webapp/01_deployment.tfstate"},
    Reconfigure: true,
  }

  //Run `terraform init` to init remote state.
  terraform.InitE(t, terraformOptions_02)
  terraform.InitE(t, terraformOptions_03)

  // Run `terraform output` to get the values of output variables from the terraform.tfstate
  resourceGroupName := terraform.Output(t, terraformOptions_02, "resource_group_name")
  sqlServerName := terraform.Output(t, terraformOptions_02, "sql_server_name")
  catalogDBName := terraform.Output(t, terraformOptions_02, "catalog_sql_db_name")
  identityDBName := terraform.Output(t, terraformOptions_02, "identity_sql_db_name")
  appResourceGroupName := terraform.Output(t, terraformOptions_03, "resource_group_name")
  appName := terraform.Output(t, terraformOptions_03, "app_service_name")
  defaultHostName := terraform.Output(t, terraformOptions_03, "default_hostname")

  // assert deployed server and databases status
  assert.Equal(t, sql.ServerStateReady, azure.GetSQLServer(t, resourceGroupName, sqlServerName, "").State, "SQl server Status")
  assert.Equal(t, "Online", *azure.GetSQLDatabase(t, resourceGroupName, sqlServerName, catalogDBName, "").Status, "Catalog SQL DB Status")
  assert.Equal(t, "Online", *azure.GetSQLDatabase(t, resourceGroupName, sqlServerName, identityDBName, "").Status, "Identity SQL DB Status")

  assert.True(t, azure.AppExists(t, appName, appResourceGroupName, ""))
  assert.Equal(t, "Running", *azure.GetAppService(t, appName, appResourceGroupName, "").State)

  httpOptions := http_helper.HttpGetOptions{Url: "https://" + defaultHostName, TlsConfig: &tls.Config{}, Timeout: 240}
  statusCode, _ := http_helper.HttpGetWithOptions(t, httpOptions)

  assert.Equal(t, 200, statusCode)
}
