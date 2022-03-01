targetScope = 'subscription'

param environment string
param location string = deployment().location
param deploymentName string = ''

var deploymentNameValidated = empty(deploymentName) ? uniqueString(subscription().subscriptionId, location, environment) : deploymentName

// Resource Group 

module resourceGroupName './../../modules/nameGeneratorSubscription.bicep' = {
  name: '${deploymentNameValidated}-resourceGroupName'
  params: {
    name: 'rg-web'
    prefix: environment
    delimiter: '-'
  }
  scope: subscription(subscription().id)
}

module resourceGroup './../../modules/resourceGroup.bicep' = {
  name: '${deploymentNameValidated}-resourceGroupDeployment'
  params: {
    name: resourceGroupName.outputs.name
    location: location
    environment: environment
  }
}

output id string = resourceGroup.outputs.id
output name string = resourceGroup.outputs.name
