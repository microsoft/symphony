param location string = resourceGroup().location
param environment string
param layerName string
param storageAccountName string
param deploymentName string = ''

var _deploymentName = empty(deploymentName)
  ? uniqueString(subscription().subscriptionId, location, environment)
  : deploymentName

// App Configuration

module appConfigName './../../modules/nameGenerator.bicep' = {
  name: '${_deploymentName}-appConfigName'
  params: {
    name: 'appconfig'
    prefix: environment
    uniqueToken: location
    suffixLength: 6
  }
}

module appConfig './modules/appconfig.bicep' = {
  name: '${_deploymentName}-appConfig'
  params: {
    name: appConfigName.outputs.name
    location: location
    environment: environment
    layerName: layerName
    configKeyValues: [
      {
        name: 'storageAccountName'
        value: storageAccountName
      }
    ]
  }
}

output appConfigResourceGroupName string = resourceGroup().name
output appConfigAccountName string = appConfig.name
output appConfigItemsLength int = length(appConfig.outputs.keys)
