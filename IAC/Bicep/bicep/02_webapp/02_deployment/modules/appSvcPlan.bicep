
param name string
param location string
param environment string

param skuName string
param skuTier string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/serverfarms?tabs=bicep
resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: name
  kind: 'linux'
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: skuName
    tier: skuTier
  }
  tags: {
    EnvironmentName: environment
    GeneratedBy: 'symphony'
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
