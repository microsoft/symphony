using './../../../../../IAC/Bicep/bicep/01_sql/02_deployment/main.bicep'

param sqlServerAdministratorLogin = readEnvironmentVariable('sqlServerAdministratorLogin')
param sqlServerAdministratorPassword=readEnvironmentVariable('sqlServerAdministratorPassword')
param environment= 'dev'
param location=readEnvironmentVariable('LOCATION_NAME','westus')
param layerName=readEnvironmentVariable('layerName')

