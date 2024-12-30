using './../../../../../IAC/Bicep/bicep/01_storage/02_deployment/main.bicep'

param environment = readEnvironmentVariable('ENVIRONMENT_NAME')
param location = readEnvironmentVariable('LOCATION_NAME', 'westus')
param layerName = readEnvironmentVariable('layerName')
