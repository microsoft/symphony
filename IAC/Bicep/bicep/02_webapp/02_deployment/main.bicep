param location string = resourceGroup().location
param environment string
param deploymentName string = ''

var deploymentNameValidated = empty(deploymentName) ? uniqueString(subscription().subscriptionId, location, environment) : deploymentName

// App Service Plan

module appSvcPlanName './../../modules/nameGenerator.bicep' = {
  name: '${deploymentNameValidated}-appSvcPlanName'
  params: {
    name: 'app-svc-plan'
    prefix: environment
    delimiter: '-'
  }
}

module appSvcPlan './modules/appSvcPlan.bicep' = {
  name: '${deploymentNameValidated}-appSvcPlanDeployment'
  params: {
    name: appSvcPlanName.outputs.name
    location: location
    environment: environment
    skuName: 'TODO VAR S1'
    skuTier: 'TODO VAR Standard'
  }
}

// App Service

module appSvcName './../../modules/nameGenerator.bicep' = {
  name: '${deploymentNameValidated}-appSvcName'
  params: {
    name: 'app-svc'
    prefix: environment
    delimiter: '-'
  }
}

module appSvc './modules/appSvc.bicep' = {
  name: '${deploymentNameValidated}-appSvcDeployment'
  params: {
    name: appSvcName.outputs.name
    location: location
    environment: environment
    appSvcPlanId: appSvcPlan.outputs.id
    dockerImage: 'TODO VAR'
    catalogDbConnectionString: 'TODO'
    identityDbConnectionString: 'TODO'
  }
}
