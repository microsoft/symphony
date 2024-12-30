using './../../../../../IAC/Bicep/bicep/02_config/02_deployment/main.bicep'

param environment = readEnvironmentVariable('ENVIRONMENT_NAME')
param location = readEnvironmentVariable('LOCATION_NAME', 'westus')
param layerName = readEnvironmentVariable('layerName')

param storageAccountName = readEnvironmentVariable('storageAccountName')
