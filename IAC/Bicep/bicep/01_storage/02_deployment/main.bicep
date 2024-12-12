param location string = resourceGroup().location
param environment string
param layerName string
param deploymentName string = ''

var _deploymentName = empty(deploymentName)
  ? uniqueString(subscription().subscriptionId, location, environment)
  : deploymentName

// Storage Account

module storageAccountName './../../modules/nameGenerator.bicep' = {
  name: '${_deploymentName}-storageAccountName'
  params: {
    name: 'storage'
    prefix: environment
    uniqueToken: location
  }
}

module storageAccount './modules/storageAccount.bicep' = {
  name: '${_deploymentName}-sqlServer'
  params: {
    name: storageAccountName.outputs.name
    location: location
    environment: environment
    layerName: layerName
  }
}

output storageAccountResourceGroupName string = resourceGroup().name
output storageAccountName string = storageAccount.name
