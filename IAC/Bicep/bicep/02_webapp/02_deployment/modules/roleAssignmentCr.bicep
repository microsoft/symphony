param containerRegistryName string
param principalId string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.containerregistry/registries?tabs=bicep
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: containerRegistryName
}

var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, containerRegistry.id, 'appSvc.name', roleDefinitionId)
  scope: containerRegistry
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
