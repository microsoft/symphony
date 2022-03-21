param location string = resourceGroup().location
param environment string
param deploymentName string = ''
param appSvcPlanSkuName string
param appSvcPlanSkuTier string
param appSvcDockerImage string
param appSvcDockerImageTag string
param catalogDbConnectionString string
param identityDbConnectionString string
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
  }
}

module appSvcPlan './modules/appSvcPlan.bicep' = {
  name: '${_deploymentName}-appSvcPlan'
  params: {
    name: appSvcPlanNameGenerator.outputs.name
    location: location
    environment: environment
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
  }
}

module appSvc './modules/appSvc.bicep' = {
  name: '${_deploymentName}-appSvc'
  params: {
    name: appSvcNameGenerator.outputs.name
    location: location
    environment: environment
    appSvcPlanId: appSvcPlan.outputs.id
    dockerImage: _dockerImage
    catalogDbConnectionString: catalogDbConnectionString
    identityDbConnectionString: identityDbConnectionString
    containerRegistryResourceGroupName: containerRegistryResourceGroupName
    containerRegistryName: containerRegistryName
  }
  dependsOn: [
    appSvcPlan
  ]
}
