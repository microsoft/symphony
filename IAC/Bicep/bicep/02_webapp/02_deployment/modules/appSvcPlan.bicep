param name string
param location string
param environment string
param layerName string

param skuName string
param skuTier string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/serverfarms?tabs=bicep
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
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
    LayerName: layerName
    GeneratedBy: 'symphony'
  }
}

output appServicePlanId string = appServicePlan.id
output appServicePlanName string = appServicePlan.name
