using './../../../../../IAC/Bicep/bicep/02_webapp/01_rg/main.bicep'

param environment= 'prod'
param location=readEnvironmentVariable('LOCATION_NAME','westus')
param layerName=readEnvironmentVariable('layerName')
