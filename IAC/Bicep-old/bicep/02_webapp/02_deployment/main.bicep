param location string = resourceGroup().location
param environment string
param layerName string
param deploymentName string = ''
param appSvcPlanSkuName string
param appSvcPlanSkuTier string
param appSvcDockerImage string
param appSvcDockerImageTag string
param sqlDatabaseCatalogDbName string
param sqlDatabaseIdentityDbName string
param sqlServerFqdn string
param sqlServerAdministratorLogin string
@secure()
param sqlServerAdministratorPassword string
param containerRegistryResourceGroupName string
param containerRegistryName string

var _deploymentName = empty(deploymentName) ? uniqueString(subscription().subscriptionId, location, environment) : deploymentName
var _dockerImage = '${appSvcDockerImage}:${appSvcDockerImageTag}'

// App Service Plan

module appSvcPlanNameGenerator './../../modules/nameGenerator.bicep' = {
  name: '${_deploymentName}-appSvcPlanNameGenerator'
  params: {
    name: 'app-svc-plan'
    prefix: environment
    uniqueToken: location
  }
}

module appSvcPlan './modules/appSvcPlan.bicep' = {
  name: '${_deploymentName}-appSvcPlan'
  params: {
    name: appSvcPlanNameGenerator.outputs.name
    location: location
    environment: environment
    layerName: layerName
    skuName: appSvcPlanSkuName
    skuTier: appSvcPlanSkuTier
  }
}

// App Service

module appSvcNameGenerator './../../modules/nameGenerator.bicep' = {
  name: '${_deploymentName}-appSvcNameGenerator'
  params: {
    name: 'app-svc'
    prefix: environment
    uniqueToken: location
  }
}

module appSvc './modules/appSvc.bicep' = {
  name: '${_deploymentName}-appSvc'
  params: {
    name: appSvcNameGenerator.outputs.name
    location: location
    environment: environment
    layerName: layerName
    appSvcPlanId: appSvcPlan.outputs.appServicePlanId
    dockerImage: _dockerImage
    catalogDbConnectionString: 'Server=tcp:${sqlServerFqdn},1433;Initial Catalog=${sqlDatabaseCatalogDbName};Persist Security Info=False;User ID=${sqlServerAdministratorLogin};Password=${sqlServerAdministratorPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
    identityDbConnectionString: 'Server=tcp:${sqlServerFqdn},1433;Initial Catalog=${sqlDatabaseIdentityDbName};Persist Security Info=False;User ID=${sqlServerAdministratorLogin};Password=${sqlServerAdministratorPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
    containerRegistryResourceGroupName: containerRegistryResourceGroupName
    containerRegistryName: containerRegistryName
  }
  dependsOn: [
    appSvcPlan
  ]
}

output appServiceResourceGroupName string = resourceGroup().name
output appServiceName string = appSvc.outputs.appServiceName
output appServicePlanId string = appSvcPlan.outputs.appServicePlanId
output appServicePlanName string = appSvcPlan.outputs.appServicePlanName
