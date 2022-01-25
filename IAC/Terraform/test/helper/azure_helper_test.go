package helper

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"os"
	"reflect"
	"testing"

	"bou.ke/monkey"
	"github.com/Azure/azure-sdk-for-go/services/postgresql/mgmt/2017-12-01/postgresql"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type KeyVaultTestConfig struct {
	Env          string `env:"TF_VAR_bar"`
	Secret       string `kv:"mysecret"`
	KeyVaultName string `kvname:"true" env:"TF_VAR_key_vault_name"`
}

func TestFetchKeyVaultSecretNormalCase(t *testing.T) {
	ExpectedKeyVaultSecretName := "mysecret"
	ExpectedKeyVaultSecretValue := "SomeSecret"
	ExpectedKeyVaultName := "mykeyvault"

	fakeGetCurrentSecret := getFakeCurrentSecret(ExpectedKeyVaultName, ExpectedKeyVaultSecretName, ExpectedKeyVaultSecretValue)
	monkey.Patch(GetCurrentSecret, fakeGetCurrentSecret)
	defer monkey.UnpatchAll()
	config := &KeyVaultTestConfig{
		Env:          "somevalue",
		KeyVaultName: ExpectedKeyVaultName,
	}
	result, err := FetchKeyVaultSecretE(config)
	require.NoError(t, err)
	config = result.(*KeyVaultTestConfig)

	assert.Equal(t, ExpectedKeyVaultSecretValue, config.Secret)
}

func TestFetchKeyVaultSecretNoKeyVaultNameCase(t *testing.T) {
	ExpectedKeyVaultSecretName := "mysecret"
	ExpectedKeyVaultSecretValue := "SomeSecret"
	ExpectedKeyVaultName := "mykeyvault"

	fakeGetCurrentSecret := getFakeCurrentSecret(ExpectedKeyVaultName, ExpectedKeyVaultSecretName, ExpectedKeyVaultSecretValue)
	monkey.Patch(GetCurrentSecret, fakeGetCurrentSecret)
	defer monkey.UnpatchAll()
	config := &KeyVaultTestConfig{
		Env:          "somevalue",
		KeyVaultName: "",
	}
	_, err := FetchKeyVaultSecretE(config)
	assert.Equal(t, "Empty KeyVault name is not allowed. Please add `kvname` on your struct *helper.KeyVaultTestConfig.KeyVaultName", err.Error())
}

func TestFetchKeyVaultSecretNoKeyValueSecretCase(t *testing.T) {
	ExpectedKeyVaultSecretName := "nosecret"
	ExpectedKeyVaultSecretValue := "SomeSecret"
	ExpectedKeyVaultName := "mykeyvault"

	fakeCurrentSecret := getFakeCurrentSecret(ExpectedKeyVaultName, ExpectedKeyVaultSecretName, ExpectedKeyVaultSecretValue)
	monkey.Patch(GetCurrentSecret, fakeCurrentSecret)
	defer monkey.UnpatchAll()
	config := &KeyVaultTestConfig{
		Env:          "somevalue",
		KeyVaultName: ExpectedKeyVaultName,
	}
	_, err := FetchKeyVaultSecretE(config)
	assert.Equal(t, fmt.Sprintf("Can not find secret KeyVault: %s, Secret: mysecret", ExpectedKeyVaultName), err.Error())
}

func getFakeCurrentSecret(ExpectedKeyVaultName, ExpectedKeyVaultSecretName, ExpectedKeyVaultSecretValue string) func(string, string) (string, error) {
	return func(keyVaultName, secretName string) (string, error) {
		if keyVaultName == ExpectedKeyVaultName && secretName == ExpectedKeyVaultSecretName {
			return ExpectedKeyVaultSecretValue, nil
		} else {
			return "", fmt.Errorf("Can not find secret KeyVault: %s, Secret: %s", keyVaultName, secretName)
		}
	}
}

func TestFetchDatabaseServerNameENormalCase(t *testing.T) {
	ExpectedServerName := "expectedServerName"
	InputServerNameSuffix := "expectedServerName"
	fakeClient := getFakeGetPostgreSQLServersClient()
	fakeList := getFakePostgreSQLList([]string{ExpectedServerName})
	monkey.Patch(GetPostgreSQLServersClient, fakeClient)
	var c postgresql.ServersClient
	monkey.PatchInstanceMethod(reflect.TypeOf(c), "List", fakeList)
	defer monkey.UnpatchAll()
	serverName, err := FetchDatabaseServerNameE(InputServerNameSuffix)
	require.NoError(t, err)
	assert.Equal(t, ExpectedServerName, serverName)
}

func TestFetchDatabaseServerNameENoHitCase(t *testing.T) {
	InputServerNameSuffix := "expectedServerName"
	fakeClient := getFakeGetPostgreSQLServersClient()
	fakeList := getFakePostgreSQLList([]string{})
	monkey.Patch(GetPostgreSQLServersClient, fakeClient)
	var c postgresql.ServersClient
	monkey.PatchInstanceMethod(reflect.TypeOf(c), "List", fakeList)
	defer monkey.UnpatchAll()
	_, err := FetchDatabaseServerNameE(InputServerNameSuffix)
	assert.Equal(t, fmt.Sprintf("Can not find the server name. ServerNamePrefix: %s", InputServerNameSuffix), err.Error())
}

func TestFetchDatabaseServerNameEMultiCase(t *testing.T) {
	ExpectedServerName1 := "expectedServerName1"
	ExpectedServerName2 := "expectedServerName2"
	InputServerNameSuffix := "expectedServerName"
	fakeClient := getFakeGetPostgreSQLServersClient()
	fakeList := getFakePostgreSQLList([]string{ExpectedServerName1, ExpectedServerName2})
	var buf bytes.Buffer
	log.SetOutput(&buf)
	defer func() {
		log.SetOutput(os.Stderr)
	}()
	monkey.Patch(GetPostgreSQLServersClient, fakeClient)
	var c postgresql.ServersClient
	monkey.PatchInstanceMethod(reflect.TypeOf(c), "List", fakeList)
	defer monkey.UnpatchAll()
	serverName, err := FetchDatabaseServerNameE(InputServerNameSuffix)
	require.NoError(t, err)
	assert.Equal(t, ExpectedServerName1, serverName)
	output := buf.String()
	assert.Contains(t, output, fmt.Sprintf("Warning: Detect more than 1 server hit against serverNamePrefix: %s Hit: [%d] %s\n", InputServerNameSuffix, 0, ExpectedServerName1))
	assert.Contains(t, output, fmt.Sprintf("Warning: Detect more than 1 server hit against serverNamePrefix: %s Hit: [%d] %s\n", InputServerNameSuffix, 1, ExpectedServerName2))

	buf.Reset()
}

func getFakeGetPostgreSQLServersClient() func() (*postgresql.ServersClient, error) {
	return func() (*postgresql.ServersClient, error) {
		client := postgresql.NewServersClient("FakeSubscription")
		return &client, nil
	}
}

func getFakePostgreSQLList(serverNames []string) func(client postgresql.ServersClient, ctx context.Context) (postgresql.ServerListResult, error) {

	var servers []postgresql.Server
	for _, name := range serverNames {
		serverName := name
		server := postgresql.Server{
			Name: &serverName,
		}
		servers = append(servers, server)
		fmt.Printf("name: %s", serverName)
	}
	listResult := postgresql.ServerListResult{
		Value: &servers,
	}
	return func(client postgresql.ServersClient, ctx context.Context) (postgresql.ServerListResult, error) {
		return listResult, nil
	}
}
