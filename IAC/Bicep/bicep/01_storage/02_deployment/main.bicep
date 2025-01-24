param location string = resourceGroup().location
param environment string
param layerName string
param deploymentName string = ''

var _deploymentName = empty(deploymentName)
  ? uniqueString(subscription().subscriptionId, location, environment)
  : deploymentName

var namePrefix = '${environment}sa'
var nameSuffix = substring(uniqueString(location, subscription().id, guid(namePrefix), resourceGroup().id), 0, 6)
var name = '${namePrefix}${nameSuffix}'

// Storage Account

module storageAccount './modules/storageAccount.bicep' = {
  name: '${_deploymentName}-storage'
  params: {
    name: name
    location: location
    environment: environment
    layerName: layerName
  }
}

output storageAccountResourceGroupName string = resourceGroup().name
output storageAccountName string = storageAccount.outputs.name
