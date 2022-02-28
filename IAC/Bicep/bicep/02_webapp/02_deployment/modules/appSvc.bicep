param name string
param location string
param environment string

param appSvcPlanId string
param dockerImage string

param catalogDbConnectionString string
param identityDbConnectionString string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites?tabs=bicep
resource appSvc 'Microsoft.Web/sites@2021-03-01' = {
  name: name
  location: location
  properties: {
    serverFarmId: appSvcPlanId
    siteConfig: {
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
    'Env': environment
  }
}

