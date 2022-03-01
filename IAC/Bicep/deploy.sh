#!/bin/bash

enviroment="dev"
parameters=$(cat parameters.${enviroment}.json)
location=$(echo ${parameters} | jq -r -c '.parameters.location.value')

# 01_sql
layer_path="01_sql"

# 01_sql | 01_rg
deployment_path="${layer_path}/01_rg"
output=$(az deployment sub create --template-file "${deployment_path}/main.bicep" --location "${location}" --parameters "@parameters.${enviroment}.json")

resource_group_id=$(echo "${output}" | jq -r -c '.properties.outputs.id.value')
resource_group_name=$(echo "${output}" | jq -r -c '.properties.outputs.name.value')
# resource_group_name="dev-rg-sql-zy4"


# 01_sql | 02_deployment
deployment_path="${layer_path}/02_deployment"
sql_password=$(openssl rand -base64 14)
output=$(az deployment group create --resource-group "${resource_group_name}" --template-file "${deployment_path}/main.bicep" --parameters @parameters.${enviroment}.json "@${deployment_path}/parameters.${enviroment}.json" sqlServerAdministratorPassword="${sql_password}")
echo "${output}"