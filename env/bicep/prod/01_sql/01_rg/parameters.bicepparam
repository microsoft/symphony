using './../../../../../IAC/Bicep/bicep/01_sql/01_rg/main.bicep'

param environment= 'prod'
param location=readEnvironmentVariable('location','westus')
param layerName=readEnvironmentVariable('layerName')
