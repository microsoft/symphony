using './../../../../../IAC/Bicep/bicep/02_webapp/01_rg/main.bicep'

param environment= 'dev'
param location=readEnvironmentVariable('location','westus')
param layerName=readEnvironmentVariable('layerName')
