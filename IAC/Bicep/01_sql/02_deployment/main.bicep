param location string = resourceGroup().location
param environment string
param deploymentName string = ''

param sqlServerAdministratorLogin string

@secure()
param sqlServerAdministratorPassword string

var _deploymentName = empty(deploymentName) ? uniqueString(subscription().subscriptionId, location, environment) : deploymentName

// SQL Server

module sqlServerName './../../modules/nameGenerator.bicep' = {
  name: '${_deploymentName}-sqlServerName'
  params: {
    name: 'sqlserver'
    prefix: environment
  }
}

module sqlServer './modules/sqlServer.bicep' = {
  name: '${_deploymentName}-sqlServer'
  params: {
    name: sqlServerName.outputs.name
    location: location
    administratorLogin: sqlServerAdministratorLogin
    administratorLoginPassword: sqlServerAdministratorPassword
    environment: environment
  }
}

// Databases

module sqlDatabaseCatalogDb './modules/sqlDatabase.bicep' = {
  name: '${_deploymentName}-sqlDatabaseCatalogDb'
  params: {
    sqlServerName: sqlServerName.outputs.name
    location: location
    environment: environment
    name: 'catalogdb'
    skuName: 'Basic'
  }
  dependsOn: [
    sqlServer
  ]
}

module sqlDatabaseIdentityDb './modules/sqlDatabase.bicep' = {
  name: '${_deploymentName}-sqlDatabaseIdentityDb'
  params: {
    sqlServerName: sqlServerName.outputs.name
    location: location
    environment: environment
    name: 'identitydb'
    skuName: 'Basic'
  }
  dependsOn: [
    sqlServer
  ]
}

output sqlServerName string = sqlServer.outputs.name

output sqlDatabaseCatalogDbName string = sqlDatabaseCatalogDb.outputs.name
output sqlDatabaseCatalogDbCS string = 'Server=tcp:${sqlServer.outputs.fqdn},1433;Initial Catalog=${sqlDatabaseCatalogDb.outputs.name};Persist Security Info=False;User ID=${sqlServerAdministratorLogin};Password=${sqlServerAdministratorPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

output sqlDatabaseIdentityDbName string = sqlDatabaseIdentityDb.outputs.name
output sqlDatabaseIdentityDbCS string = 'Server=tcp:${sqlServer.outputs.fqdn},1433;Initial Catalog=${sqlDatabaseIdentityDb.outputs.name};Persist Security Info=False;User ID=${sqlServerAdministratorLogin};Password=${sqlServerAdministratorPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
