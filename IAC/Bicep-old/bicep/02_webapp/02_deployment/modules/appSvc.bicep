param name string
param location string
param environment string
param layerName string

param appSvcPlanId string
param dockerImage string

@secure()
param catalogDbConnectionString string
@secure()
param identityDbConnectionString string

param containerRegistryResourceGroupName string
param containerRegistryName string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites?tabs=bicep
resource appSvc 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appSvcPlanId
    siteConfig: {
      acrUseManagedIdentityCreds: true
      linuxFxVersion: 'DOCKER|${dockerImage}'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Docker'
        }
        {
          name: 'ASPNETCORE_URL'
          value: 'http://+:80'
        }
      ]
      connectionStrings: [
        {
          connectionString: catalogDbConnectionString
          name: 'CatalogConnection'
          type: 'SQLAzure'
        }
        {
          connectionString: identityDbConnectionString
          name: 'IdentityConnection'
          type: 'SQLAzure'
        }
      ]
    }
  }
  tags: {
    EnvironmentName: environment
    LayerName: layerName
    GeneratedBy: 'symphony'
  }
}

output appServiceName string = appSvc.name

module roleAssignmentCr 'roleAssignmentCr.bicep' = {
  name: '${deployment().name}-roleAssignmentCr'
  params: {
    containerRegistryName: containerRegistryName
    principalId: appSvc.identity.principalId
    objectResourceId: appSvc.id
  }
  scope:resourceGroup(containerRegistryResourceGroupName)
}
