targetScope = 'subscription'

param name string
param location string
param environment string
param layerName string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.resources/resourcegroups?tabs=bicep
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: name
  location: location
  tags: {
    EnvironmentName: environment
    LayerName: layerName
    GeneratedBy: 'symphony'
  }
}

output name string = resourceGroup.name
output id string = resourceGroup.id
