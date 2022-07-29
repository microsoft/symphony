targetScope = 'subscription'

param name string
param location string
param environment string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.resources/resourcegroups?tabs=bicep
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location
  tags: {
    Env: environment
    GeneratedBy: 'symphony'
  }
}

output name string = resourceGroup.name
output id string = resourceGroup.id
