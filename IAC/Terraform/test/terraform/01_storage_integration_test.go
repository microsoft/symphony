// +build 01

package terraform

import (
	"testing"

	"dev.azure.com/csedevops/terraform-template-public/test/helper"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type StorageConfig struct {
	AccountName       string `env:"TF_VAR_BACKEND_STORAGE_ACCOUNT_NAME"`
	ResourceGroupName string `env:"TF_VAR_BACKEND_RESOURCE_GROUP_NAME"`
	ContainerName     string `env:"TF_VAR_BACKEND_CONTAINER_NAME"`
}

func TestStaticTest_01_storage_test(t *testing.T) {
	helper.LoadEnvFile(t)
	config := helper.DeserializeVariablesStruct(&StorageConfig{}).(*StorageConfig)
	assert.True(t, helper.ValidateVariablesStruct(config, true))

}

func Test01_Init_Storage(t *testing.T) {
	teardownTestCase := helper.SetupTestCase(t)
	defer teardownTestCase(t)
	config := helper.DeserializeVariablesStruct(&StorageConfig{}).(*StorageConfig)
	assert.True(t, helper.ValidateVariablesStruct(config, false))

	// GetStorageAccount
	account, err := helper.GetStorageAccountProperty(config.ResourceGroupName, config.AccountName)
	require.NoError(t, err)
	assert.Equal(t, "Standard_RAGRS", string(account.Sku.Name))
	container, err := helper.GetBlobContainer(config.ResourceGroupName, config.AccountName, config.ContainerName)
	require.NoError(t, err)
	assert.Equal(t, config.ContainerName, *container.Name)
}
