#!/bin/bash

enviroment="dev"
parameters_root_path="../../env/bicep/${enviroment}"
parameters=$(cat "${parameters_root_path}/parameters.json")
location=$(echo "${parameters}" | jq -r -c '.parameters.location.value')

# 01_sql
layer="01_sql"
layer_path="bicep/${layer}"

# 01_sql | 01_rg
deployment="01_rg"
deployment_path="${layer_path}/${deployment}"
output=$(az deployment sub create --template-file "${deployment_path}/main.bicep" --location "${location}" --parameters "@${parameters_root_path}/parameters.json")
resource_group_name=$(echo "${output}" | jq -r -c '.properties.outputs.name.value')

# 01_sql | 02_deployment
deployment="02_deployment"
deployment_path="${layer_path}/${deployment}"
sql_password=$(openssl rand -base64 14)
output=$(az deployment group create --resource-group "${resource_group_name}" --template-file "${deployment_path}/main.bicep" --parameters "@${parameters_root_path}/parameters.json" "@${parameters_root_path}/${layer}_${deployment}.json" sqlServerAdministratorPassword="${sql_password}")
catalogdb_cs=$(echo "${output}" | jq -r -c '.properties.outputs.sqlDatabaseCatalogDbCS.value')
identitydb_cs=$(echo "${output}" | jq -r -c '.properties.outputs.sqlDatabaseIdentityDbCS.value')

# 02_webapp
layer="02_webapp"
layer_path="bicep/${layer}"

# 02_webapp | 01_rg
deployment="01_rg"
deployment_path="${layer_path}/${deployment}"
output=$(az deployment sub create --template-file "${deployment_path}/main.bicep" --location "${location}" --parameters "@${parameters_root_path}/parameters.json")
resource_group_name=$(echo "${output}" | jq -r -c '.properties.outputs.name.value')

# 02_webapp | 02_deployment
deployment="02_deployment"
deployment_path="${layer_path}/${deployment}"
output=$(az deployment group create --resource-group "${resource_group_name}" --template-file "${deployment_path}/main.bicep" --parameters "@${parameters_root_path}/parameters.json" "@${parameters_root_path}/${layer}_${deployment}.json" catalogDbConnectionString="${catalogdb_cs}" identityDbConnectionString="${identitydb_cs}")
