#!/bin/bash

enviroment="dev"
parameters=$(cat parameters.${enviroment}.json)
location=$(echo ${parameters} | jq -r -c '.parameters.location.value')

# 01_sql
layer_path="01_sql"

# 01_sql | 01_rg
deployment_path="${layer_path}/01_rg"
output=$(az deployment sub create --template-file "${deployment_path}/main.bicep" --location "${location}" --parameters "@parameters.${enviroment}.json")
resource_group_name=$(echo "${output}" | jq -r -c '.properties.outputs.name.value')

# 01_sql | 02_deployment
deployment_path="${layer_path}/02_deployment"
# sql_password=$(openssl rand -base64 14)
sql_password="demo!P@55w0rd123"
output=$(az deployment group create --resource-group "${resource_group_name}" --template-file "${deployment_path}/main.bicep" --parameters "@parameters.${enviroment}.json" "@${deployment_path}/parameters.${enviroment}.json" sqlServerAdministratorPassword="${sql_password}")
catalogdb_cs=$(echo "${output}" | jq -r -c '.properties.outputs.sqlDatabaseCatalogDbCS.value')
identitydb_cs=$(echo "${output}" | jq -r -c '.properties.outputs.sqlDatabaseIdentityDbCS.value')

# 02_webapp
layer_path="02_webapp"

# 02_webapp | 01_rg
deployment_path="${layer_path}/01_rg"
output=$(az deployment sub create --template-file "${deployment_path}/main.bicep" --location "${location}" --parameters "@parameters.${enviroment}.json")
resource_group_name=$(echo "${output}" | jq -r -c '.properties.outputs.name.value')

# 02_webapp | 02_deployment
deployment_path="${layer_path}/02_deployment"
output=$(az deployment group create --resource-group "${resource_group_name}" --template-file "${deployment_path}/main.bicep" --parameters "@parameters.${enviroment}.json" "@${deployment_path}/parameters.${enviroment}.json" catalogDbConnectionString="${catalogdb_cs}" identityDbConnectionString="${identitydb_cs}")
