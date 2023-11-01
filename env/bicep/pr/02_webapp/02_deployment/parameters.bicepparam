using './../../../../../IAC/Bicep/bicep/02_webapp/02_deployment/main.bicep'

param environment=readEnvironmentVariable('ENVIRONMENT_NAME')
param location=readEnvironmentVariable('LOCATION_NAME','westus')
param layerName=readEnvironmentVariable('layerName')

param appSvcPlanSkuName='S1'
param appSvcPlanSkuTier='Standard'
param appSvcDockerImage='crsymphony360.azurecr.io/eshopwebmvc'
param appSvcDockerImageTag='a72dd77'
param containerRegistryResourceGroupName='devops-symphony-362'
param containerRegistryName='crsymphony360'
param sqlDatabaseCatalogDbName=readEnvironmentVariable('sqlDatabaseCatalogDbName')
param sqlDatabaseIdentityDbName=readEnvironmentVariable('sqlDatabaseIdentityDbName')
param sqlServerFqdn=readEnvironmentVariable('sqlServerFqdn')
param sqlServerAdministratorLogin=readEnvironmentVariable('sqlServerAdministratorLogin')
param sqlServerAdministratorPassword=readEnvironmentVariable('sqlServerAdministratorPassword')
