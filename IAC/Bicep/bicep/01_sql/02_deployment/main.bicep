param location string = resourceGroup().location
param environment string
param deploymentName string = ''

var deploymentNameValidated = empty(deploymentName) ? uniqueString(subscription().subscriptionId, location, environment) : deploymentName

// SQL Server

module administratorLogin './../../modules/randomGenerator.bicep' = {
  name: '${deploymentNameValidated}-administratorLogin'
}

module administratorLoginPassword './../../modules/randomGenerator.bicep' = {
  name: '${deploymentNameValidated}-administratorLoginPassword'
}

module sqlServerName './../../modules/nameGenerator.bicep' = {
  name: '${deploymentNameValidated}-sqlServerName'
  params: {
    name: 'sqlserver'
    prefix: environment
    delimiter: '-'
  }
}

module sqlServer './modules/sqlServer.bicep' = {
  name: '${deploymentNameValidated}-sqlServerDeployment'
  params: {
    name: sqlServerName.outputs.name
    location: location
    administratorLogin: administratorLogin.outputs.string
    administratorLoginPassword: administratorLoginPassword.outputs.string
    environment: environment
  }
}

// Databases

module sqlDatabaseCatalogDb './modules/sqlDatabase.bicep' = {
  name: '${deploymentNameValidated}-sqlDatabaseCatalogDbDeployment'
  params: {
    sqlServerName: sqlServerName.outputs.name
    location: location
    environment: environment
    name: 'catalogdb'
    skuName: 'Basic'
  }
}

module sqlDatabaseIdentityDb './modules/sqlDatabase.bicep' = {
  name: '${deploymentNameValidated}-sqlDatabaseIdentityDbDeployment'
  params: {
    sqlServerName: sqlServerName.outputs.name
    location: location
    environment: environment
    name: 'identitydb'
    skuName: 'Basic'
  }
}

output sqlServerName string = sqlServer.outputs.name

output sqlDatabaseCatalogDbName string = sqlDatabaseCatalogDb.outputs.name
output sqlDatabaseCatalogDbCS string = 'Server=tcp:${sqlServer.outputs.fqdn},1433;Initial Catalog=${sqlDatabaseCatalogDb.outputs.name};Persist Security Info=False;User ID=${administratorLogin.outputs.string};Password=${administratorLoginPassword.outputs.string};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

output sqlDatabaseIdentityDbName string = sqlDatabaseIdentityDb.outputs.name
output sqlDatabaseIdentityDbCS string = 'Server=tcp:${sqlServer.outputs.fqdn},1433;Initial Catalog=${sqlDatabaseIdentityDb.outputs.name};Persist Security Info=False;User ID=${administratorLogin.outputs.string};Password=${administratorLoginPassword.outputs.string};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
