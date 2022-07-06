targetScope = 'subscription'

param environment string
param location string = deployment().location
param deploymentName string = ''
param resourceGroupName string = ''

var _resourceGroupName = empty(deploymentName) ? resourceGroupNameGenerator.outputs.name : resourceGroupName
var _deploymentName = empty(deploymentName) ? uniqueString(subscription().subscriptionId, location, environment) : deploymentName

param randomName string = newGuid()

// Resource Group

module resourceGroupNameGenerator './../../modules/nameGeneratorSubscription.bicep' = {
  name: '${_deploymentName}-resourceGroupNameGenerator'
  params: {
    suffix: substring(uniqueString(randomName), 0, 3)
    name: 'rg-sql'
    prefix: environment
  }
}

module resourceGroup './../../modules/resourceGroup.bicep' = {
  name: '${_deploymentName}-resourceGroup'
  params: {
    name: _resourceGroupName
    location: location
    environment: environment
  }
}

output resourceGroupId string = resourceGroup.outputs.id
output resourceGroupName string = resourceGroup.outputs.name
