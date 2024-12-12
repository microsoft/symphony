param name string
param location string
param environment string
param layerName string

// Storage Account

// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: {
    EnvironmentName: environment
    LayerName: layerName
    GeneratedBy: 'symphony'
  }
}

output id string = storageAccount.id
output name string = storageAccount.name
