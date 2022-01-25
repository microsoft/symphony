package helper

import (
	"context"
	"fmt"
	"io/ioutil"
	"log"
	"net/url"
	"os"
	"reflect"
	"sort"
	"strings"

	"github.com/Azure/azure-sdk-for-go/services/containerservice/mgmt/2020-02-01/containerservice"
	kvauth "github.com/Azure/azure-sdk-for-go/services/keyvault/auth"
	"github.com/Azure/azure-sdk-for-go/services/keyvault/v7.0/keyvault"
	"github.com/Azure/azure-sdk-for-go/services/network/mgmt/2019-09-01/network"
	"github.com/Azure/azure-sdk-for-go/services/postgresql/mgmt/2017-12-01/postgresql"
	"github.com/Azure/azure-sdk-for-go/services/storage/mgmt/2019-06-01/storage"
	"github.com/Azure/azure-storage-file-go/azfile"
	"github.com/Azure/go-autorest/autorest"
	"github.com/Azure/go-autorest/autorest/azure/auth"
)

const (
	// SubscriptionIDEnvName azure sub name
	SubscriptionIDEnvName = "ARM_SUBSCRIPTION_ID"
)

//GetAllSubClientsE gets all virtual network subclients name, and address prefix
func GetAllSubClientsE(resourceGroupName, virtualNetworkName string) (*map[string]string, error) {
	client, err := GetSubNetClient(os.Getenv(SubscriptionIDEnvName))
	if err != nil {
		return nil, err
	}

	subnets, err := client.List(context.Background(), resourceGroupName, virtualNetworkName)
	if err != nil {
		return nil, err
	}

	subNetDetails := make(map[string]string)
	for _, v := range subnets.Values() {
		subnetName := v.Name

		subnetProperties := v.SubnetPropertiesFormat
		subNetAddressPrefix := subnetProperties.AddressPrefix

		subNetDetails[*subnetName] = *subNetAddressPrefix
	}
	return &subNetDetails, nil
}

// GetSubNetClient creates a virtual network subnet client
func GetSubNetClient(subscriptionID string) (*network.SubnetsClient, error) {
	subNetClient := network.NewSubnetsClient(subscriptionID)
	authorizer, err := NewAuthorizer()

	if err != nil {
		return nil, err
	}

	subNetClient.Authorizer = *authorizer
	return &subNetClient, nil
}

// GetVirtualNetworkE gets virtual network object
func GetVirtualNetworkE(resourceGroupName, virtualNetworkName string) (*network.VirtualNetwork, error) {

	client, err := GetVirtualNetworksClient(os.Getenv(SubscriptionIDEnvName))
	if err != nil {
		return nil, err
	}
	virtualNetwork, err := client.Get(context.Background(), resourceGroupName, virtualNetworkName, "")
	if err != nil {
		return nil, err
	}
	return &virtualNetwork, nil
}

// GetVirtualNetworksClient creates a virtual network client
func GetVirtualNetworksClient(subscriptionID string) (*network.VirtualNetworksClient, error) {
	vnClient := network.NewVirtualNetworksClient(subscriptionID)
	authorizer, err := NewAuthorizer()

	if err != nil {
		return nil, err
	}

	vnClient.Authorizer = *authorizer
	return &vnClient, nil
}

// GetStorageAccountClient creates a storage account client.
func GetStorageAccountClient(subscriptionID string) (*storage.AccountsClient, error) {
	storageAccountClient := storage.NewAccountsClient(subscriptionID)
	authorizer, err := NewAuthorizer()
	if err != nil {
		return nil, err
	}
	storageAccountClient.Authorizer = *authorizer
	return &storageAccountClient, nil
}

// GetStorageAccountProperty return StorageAccount that matches the parameter.
func GetStorageAccountProperty(resourceGroupName, storageAccountName string) (*storage.Account, error) {
	client, err := GetStorageAccountClient(os.Getenv(SubscriptionIDEnvName))
	if err != nil {
		return nil, err
	}
	account, err := client.GetProperties(context.Background(), resourceGroupName, storageAccountName, "")
	if err != nil {
		return nil, err
	}
	return &account, nil
}

// GetBlobContainersClient creates a storage container client.
func GetBlobContainersClient(subscriptionID string) (*storage.BlobContainersClient, error) {
	blobContainerClient := storage.NewBlobContainersClient(subscriptionID)
	authorizer, err := NewAuthorizer()

	if err != nil {
		return nil, err
	}
	blobContainerClient.Authorizer = *authorizer
	return &blobContainerClient, nil
}

// GetBlobContainer returns Blob container client
func GetBlobContainer(resourceGroupName, storageAccountName, containerName string) (*storage.BlobContainer, error) {
	client, err := GetBlobContainersClient(os.Getenv(SubscriptionIDEnvName))
	if err != nil {
		return nil, err
	}
	container, err := client.Get(context.Background(), resourceGroupName, storageAccountName, containerName)
	if err != nil {
		return nil, err
	}
	return &container, nil
}

// AzureFileShareClient is store credentials and metadata.
type AzureFileShareClient struct {
	Credential         *azfile.SharedKeyCredential
	StorageAccountName string
	FileShareName      string
}

// GetAzureFileShareClientE returns a client of Azure File Share.
func GetAzureFileShareClientE(accountName, fileShare, accountKey string) (*AzureFileShareClient, error) {
	credential, err := azfile.NewSharedKeyCredential(accountName, accountKey)
	if err != nil {
		return nil, err
	}
	return &AzureFileShareClient{
		Credential:         credential,
		StorageAccountName: accountName,
		FileShareName:      fileShare,
	}, nil
}

func (c *AzureFileShareClient) getAzureFileURL(azureFileName string) azfile.FileURL {
	url, _ := url.Parse(fmt.Sprintf("https://%s.file.core.windows.net/%s/%s", c.StorageAccountName, c.FileShareName, azureFileName))
	return azfile.NewFileURL(*url, azfile.NewPipeline(c.Credential, azfile.PipelineOptions{}))
}

// DownloadAzureFileToFile download file to the local file system.
func (c *AzureFileShareClient) DownloadAzureFileToFile(azureFileName, localFileName string) error {
	fileURL := c.getAzureFileURL(azureFileName)
	localFile, err := os.Create(localFileName)
	if err != nil {
		return err
	}
	defer localFile.Close()
	downloadResponse, err := azfile.DownloadAzureFileToFile(context.Background(), fileURL, localFile,
		azfile.DownloadFromAzureFileOptions{
			Parallelism:              3,
			MaxRetryRequestsPerRange: 2,
			Progress: func(bytesTransferred int64) {
				fmt.Printf("Downloaded %d bytes.\n", bytesTransferred)
			},
		})
	if err != nil {
		return err
	}

	lastModified := downloadResponse.LastModified() // Check if the propery download the file
	_ = lastModified                                // Avoid compiler complains.
	return nil
}

// GetStorageAccountCredentialE will create Credential for accessing Storage account
func GetStorageAccountCredentialE(accountName, accountKey string) (*azfile.SharedKeyCredential, error) {
	return azfile.NewSharedKeyCredential(accountName, accountKey)
}

// NewAuthorizer will return Authorizer
func NewAuthorizer() (*autorest.Authorizer, error) {
	authorizer, err := auth.NewAuthorizerFromCLI()
	return &authorizer, err
}

// NewKeyVaultAuthorizer witll return Authorizer for KeyVault
func NewKeyVaultAuthorizer() (*autorest.Authorizer, error) {
	authorizer, err := kvauth.NewAuthorizerFromCLI()
	return &authorizer, err
}

// GetKeyVaultClient creates a KeyVault client
func GetKeyVaultClient() (*keyvault.BaseClient, error) {
	kvClient := keyvault.New()
	authorizer, err := NewKeyVaultAuthorizer()

	if err != nil {
		return nil, err
	}

	kvClient.Authorizer = *authorizer
	return &kvClient, nil
}

// GetKeyVaultSecretCurrentVersion gets the current version of the KeyVault
// e.g. https://foo.vault.azure.net/secrets/BAR/194bd7da9aa54944ab316faebd9120d0 -> 194bd7da9aa54944ab316faebd9120d0
func GetKeyVaultSecretCurrentVersion(keyVaultName, secretName string) (string, error) {
	client, err := GetKeyVaultClient()
	if err != nil {
		return "", err
	}
	var maxVersionsCount int32 = 25
	versions, err := client.GetSecretVersions(context.Background(),
		fmt.Sprintf("https://%s.vault.azure.net/", keyVaultName),
		secretName,
		&maxVersionsCount)
	if err != nil {
		return "", err
	}
	items := versions.Values()
	sort.Slice(items, func(i, j int) bool {
		return (*items[i].Attributes.Updated).Duration().Milliseconds() > (*items[j].Attributes.Updated).Duration().Milliseconds()
	})
	nonVersion := fmt.Sprintf("https://%s.vault.azure.net/secrets/%s/", keyVaultName, secretName)
	return strings.Replace(*items[0].ID, nonVersion, "", 1), nil
}

// GetSecret is get secret from the specific key vault.
func GetSecret(keyVaultName, secretName, version string) (string, error) {
	client, err := GetKeyVaultClient()
	if err != nil {
		return "", err
	}
	secret, err := client.GetSecret(context.Background(), fmt.Sprintf("https://%s.vault.azure.net/", keyVaultName), secretName, version)
	if err != nil {
		return "", err
	}
	return *secret.Value, err
}

// GetCurrentSecret returns current secret
func GetCurrentSecret(keyVaultName, secretName string) (string, error) {
	version, err := GetKeyVaultSecretCurrentVersion(keyVaultName, secretName)
	if err != nil {
		return "", err
	}
	secret, err := GetSecret(keyVaultName, secretName, version)
	if err != nil {
		return "", err
	}
	return secret, nil
}

// FetchKeyVaultSecretE fill the value from keyvault
func FetchKeyVaultSecretE(s interface{}) (interface{}, error) {
	keyVaultName, err := getKeyVaultName(s)
	if err != nil {
		return nil, err
	}

	fields := reflect.ValueOf(s).Elem()
	for i := 0; i < fields.NumField(); i++ {
		typeField := fields.Type().Field(i)
		if typeField.Tag.Get("kv") != "" {
			secretName := typeField.Tag.Get("kv")
			if fields.Field(i).Kind() == reflect.String {
				fmt.Printf("KeyVaultName: %s Secret: %s \n", keyVaultName, secretName)
				secret, err := GetCurrentSecret(keyVaultName, secretName)
				if err != nil {
					return nil, err
				}
				fields.Field(i).SetString(secret)
			}
		}

	}
	return s, nil
}

func getKeyVaultName(s interface{}) (string, error) {
	structName := reflect.TypeOf(s)
	fields := reflect.ValueOf(s).Elem()
	for i := 0; i < fields.NumField(); i++ {
		typeField := fields.Type().Field(i)
		if len(typeField.Tag.Get("kvname")) != 0 {
			if fields.Field(i).Kind() == reflect.String {
				kvname := fields.Field(i).String()
				kvNameField := fields.Type().Field(i).Name
				if len(kvname) == 0 {
					return "", fmt.Errorf("Empty KeyVault name is not allowed. Please add `kvname` on your struct %s.%s", structName, kvNameField)
				}
				return fields.Field(i).String(), nil
			}
		}
	}
	return "", fmt.Errorf("Can not find kvname filed on your struct %s", structName)
}

// GetPostgreSQLServersClient returns postgresql server client.
func GetPostgreSQLServersClient() (*postgresql.ServersClient, error) {
	client := postgresql.NewServersClient(os.Getenv(SubscriptionIDEnvName))
	authorizer, err := NewAuthorizer()
	client.Authorizer = *authorizer
	return &client, err
}

// FetchDatabaseServerNameE get ServerName. It assume the servername that match is only one.
// If there are multiple servers hits, it assume the first one is the one with warning message output.
func FetchDatabaseServerNameE(serverNamePrefix string) (string, error) {
	client, err := GetPostgreSQLServersClient()
	if err != nil {
		return "", err
	}
	result, err := client.List(context.Background())
	if err != nil {
		return "", err
	}

	var matchServers []string

	for _, s := range *result.Value {
		if strings.Index(*s.Name, serverNamePrefix) != -1 {
			matchServers = append(matchServers, *s.Name)
		}
	}

	if len(matchServers) == 0 {
		return "", fmt.Errorf("Can not find the server name. ServerNamePrefix: %s", serverNamePrefix)
	}
	if len(matchServers) != 1 {
		for index, name := range matchServers {
			log.Printf("Warning: Detect more than 1 server hit against serverNamePrefix: %s Hit: [%d] %s\n", serverNamePrefix, index, name)
		}
	}
	return matchServers[0], nil
}

// GetApplicationGatewayE will return ApplicationGateway object and an error object
func GetApplicationGatewayE(resourceGroupName, applicationGatewayName string) (*network.ApplicationGateway, error) {
	client, err := GetApplicationGatewayClientE(os.Getenv(SubscriptionIDEnvName))
	if err != nil {
		return nil, err
	}
	applicationGateway, err := client.Get(context.Background(), resourceGroupName, applicationGatewayName)
	if err != nil {
		return nil, err
	}
	return &applicationGateway, nil
}

// GetPublicIPAddressE will return ApplicationGateway object and an error object
func GetPublicIPAddressE(resourceGroupName, publicIPAddressName string) (*network.PublicIPAddress, error) {
	client, err := GetPublicIPAddressClientE(os.Getenv(SubscriptionIDEnvName))
	if err != nil {
		return nil, err
	}
	publicIPAddress, err := client.Get(context.Background(), resourceGroupName, publicIPAddressName, "")
	if err != nil {
		return nil, err
	}
	return &publicIPAddress, nil
}

// GetApplicationGatewayClientE creates a ApplicationGatewaysClient client
func GetApplicationGatewayClientE(subscriptionID string) (*network.ApplicationGatewaysClient, error) {
	client := network.NewApplicationGatewaysClient(subscriptionID)
	authorizer, err := NewAuthorizer()
	if err != nil {
		return nil, err
	}
	client.Authorizer = *authorizer
	return &client, nil
}

// GetPublicIPAddressClientE creates a PublicIPAddresses client
func GetPublicIPAddressClientE(subscriptionID string) (*network.PublicIPAddressesClient, error) {
	client := network.NewPublicIPAddressesClient(subscriptionID)
	authorizer, err := NewAuthorizer()
	if err != nil {
		return nil, err
	}
	client.Authorizer = *authorizer
	return &client, nil
}

// GetClusterAdminCredentialsE returns credential information includes kubeconfig
func GetClusterAdminCredentialsE(resourceGroupName, clusterName string) (*containerservice.CredentialResults, error) {
	client, err := GetManagedClustersClientE(os.Getenv(SubscriptionIDEnvName))
	if err != nil {
		return nil, err
	}

	credentials, err := client.ListClusterAdminCredentials(context.Background(), resourceGroupName, clusterName)
	if err != nil {
		return nil, err
	}
	return &credentials, nil
}

// WriteKubeconfigFromCredentialsE writes a kubeconfig file
func WriteKubeconfigFromCredentialsE(credentialResults *containerservice.CredentialResults, filePath string) error {
	kubeconfig := (*(*credentialResults.Kubeconfigs)[0].Value)
	return ioutil.WriteFile(filePath, kubeconfig, os.ModePerm)
}

// GetContainerServiceE will return ContainerService object and an error object
func GetManagedClusterE(resourceGroupName, clusterName string) (*containerservice.ManagedCluster, error) {
	client, err := GetManagedClustersClientE(os.Getenv(SubscriptionIDEnvName))
	if err != nil {
		return nil, err
	}
	managedCluster, err := client.Get(context.Background(), resourceGroupName, clusterName)
	if err != nil {
		return nil, err
	}
	return &managedCluster, nil
}

// GetContainerServiceClientE creates a ContainerServicesClient client
func GetManagedClustersClientE(subscriptionID string) (*containerservice.ManagedClustersClient, error) {
	client := containerservice.NewManagedClustersClient(subscriptionID)
	authorizer, err := NewAuthorizer()
	if err != nil {
		return nil, err
	}
	client.Authorizer = *authorizer
	return &client, nil
}
