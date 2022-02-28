param sqlServerName string
param location string
param environment string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers?tabs=bicep
resource sqlServer 'Microsoft.Sql/servers@2021-08-01-preview' existing = {
  name: sqlServerName
}

// DATABASES

// https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers/databases?tabs=bicep
resource sqlDatabaseCatalogDb 'Microsoft.Sql/servers/databases@2021-08-01-preview' = {
  parent: sqlServer
  name: 'catalogdb'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
  tags:{
    'Env': environment
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers/databases?tabs=bicep
resource sqlDatabaseIdentityDb 'Microsoft.Sql/servers/databases@2021-08-01-preview' = {
  parent: sqlServer
  name: 'identitydb'
  location: location
  sku: {
    name: 'Basic'
  }
  tags:{
    'Env': environment
  }
}

output catalogDbId string = sqlDatabaseCatalogDb.id
output catalogDbName string = sqlDatabaseCatalogDb.name

output identityDbId string = sqlDatabaseIdentityDb.id
output identityDbName string = sqlDatabaseIdentityDb.name
