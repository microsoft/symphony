targetScope = 'subscription'

param environment string
param layerName string
param location string = deployment().location
param deploymentName string = ''
param resourceGroupName string = ''

var _resourceGroupName = empty(deploymentName) ? resourceGroupNameGenerator.outputs.name : resourceGroupName
var _deploymentName = empty(deploymentName) ? uniqueString(subscription().subscriptionId, location, environment) : deploymentName

// Resource Group

module resourceGroupNameGenerator './../../modules/nameGeneratorSubscription.bicep' = {
  name: '${_deploymentName}-resourceGroupNameGenerator'
  params: {
    name: 'rg-web'
    prefix: environment
    uniqueToken: location
  }
}

module resourceGroup './../../modules/resourceGroup.bicep' = {
  name: '${_deploymentName}-resourceGroup'
  params: {
    name: _resourceGroupName
    location: location
    environment: environment
    layerName: layerName
  }
}

output resourceGroupId string = resourceGroup.outputs.id
output resourceGroupName string = resourceGroup.outputs.name
