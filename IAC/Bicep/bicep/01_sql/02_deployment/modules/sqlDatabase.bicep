param sqlServerName string
param name string
param location string
param environment string
param skuName string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers?tabs=bicep
resource sqlServer 'Microsoft.Sql/servers@2021-08-01-preview' existing = {
  name: sqlServerName
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers/databases?tabs=bicep
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-08-01-preview' = {
  parent: sqlServer
  name: name
  location: location
  sku: {
    name: skuName
  }
  tags:{
    Env: environment
  }
}

output id string = sqlDatabase.id
output name string = sqlDatabase.name
