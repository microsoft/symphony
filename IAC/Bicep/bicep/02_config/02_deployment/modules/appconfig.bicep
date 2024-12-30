param name string
param location string
param environment string
param layerName string
param configKeyValues object[]

// App Configuration

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appconfiguration/configurationstores?pivots=deployment-language-bicep
resource appConfig 'Microsoft.AppConfiguration/configurationStores@2022-05-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
  }
  tags: {
    EnvironmentName: environment
    LayerName: layerName
    GeneratedBy: 'symphony'
  }
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appconfiguration/configurationstores/keyvalues?pivots=deployment-language-bicep
resource appConfigEntries 'Microsoft.AppConfiguration/configurationStores/keyValues@2022-05-01' = [
  for kv in configKeyValues: {
    name: kv.name
    parent: appConfig
    properties: {
      value: kv.value
      contentType: 'text/plain'
    }
  }
]

output id string = appConfig.id
output name string = appConfig.name
output keys array = [for kv in configKeyValues: kv.name]
