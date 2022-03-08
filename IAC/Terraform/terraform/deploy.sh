#!/bin/bash

declare enviroment="dev"

# 01_init
layer_path="01_init"
pushd "${layer_path}"
terraform init
terraform plan -var-file="${enviroment}.tfvars.json" -state="${enviroment}.tfstate" -out="${enviroment}.plan"
terraform apply -state="${enviroment}.tfstate" -auto-approve "${enviroment}.plan"

tfstate_tfvars=$(cat "${enviroment}.tfvars.json")
TFSTATE_RESOURCES_GROUP_NAME=$(echo ${tfstate_tfvars} | jq -r -c '.resource_group_name')
TFSTATE_STORAGE_ACCOUNT_NAME=$(echo ${tfstate_tfvars} | jq -r -c '.storage_account_name')
TFSTATE_STORAGE_CONTAINER_NAME=$(echo ${tfstate_tfvars} | jq -r -c '.container_name')
popd

# 02_sql
layer_path="02_sql"
deployment_path="${layer_path}/01_deployment"
TFSTATE_KEY="02_sql/01_deployment"
pushd "${deployment_path}"
terraform init -backend-config=storage_account_name="${TFSTATE_STORAGE_ACCOUNT_NAME}" -backend-config=container_name="${TFSTATE_STORAGE_CONTAINER_NAME}" -backend-config=key="${TFSTATE_KEY}" -backend-config=resource_group_name="${TFSTATE_RESOURCES_GROUP_NAME}"
terraform plan -var-file="${enviroment}.tfvars.json" -out="${enviroment}.plan"
terraform apply -auto-approve "${enviroment}.plan"
popd

# 02_webapp
layer_path="02_webapp"
deployment_path="${layer_path}/01_deployment"
TFSTATE_KEY="02_webapp/01_deployment"
pushd "${deployment_path}"
terraform init -backend-config=storage_account_name="${TFSTATE_STORAGE_ACCOUNT_NAME}" -backend-config=container_name="${TFSTATE_STORAGE_CONTAINER_NAME}" -backend-config=key="${TFSTATE_KEY}" -backend-config=resource_group_name="${TFSTATE_RESOURCES_GROUP_NAME}"
terraform plan -var-file="${enviroment}.tfvars.json" -out="${enviroment}.plan"
terraform apply -auto-approve "${enviroment}.plan"
popd





# parameters=$(cat parameters.${enviroment}.json)
# location=$(echo ${parameters} | jq -r -c '.parameters.location.value')



# # 01_sql | 01_rg
# deployment_path="${layer_path}/01_rg"
# output=$(az deployment sub create --template-file "${deployment_path}/main.bicep" --location "${location}" --parameters "@parameters.${enviroment}.json")
# resource_group_name=$(echo "${output}" | jq -r -c '.properties.outputs.name.value')

# # 01_sql | 02_deployment
# deployment_path="${layer_path}/02_deployment"
# sql_password=$(openssl rand -base64 14)
# output=$(az deployment group create --resource-group "${resource_group_name}" --template-file "${deployment_path}/main.bicep" --parameters "@parameters.${enviroment}.json" "@${deployment_path}/parameters.${enviroment}.json" sqlServerAdministratorPassword="${sql_password}")
# catalogdb_cs=$(echo "${output}" | jq -r -c '.properties.outputs.sqlDatabaseCatalogDbCS.value')
# identitydb_cs=$(echo "${output}" | jq -r -c '.properties.outputs.sqlDatabaseIdentityDbCS.value')

# # 02_webapp
# layer_path="02_webapp"

# # 02_webapp | 01_rg
# deployment_path="${layer_path}/01_rg"
# output=$(az deployment sub create --template-file "${deployment_path}/main.bicep" --location "${location}" --parameters "@parameters.${enviroment}.json")
# resource_group_name=$(echo "${output}" | jq -r -c '.properties.outputs.name.value')

# # 02_webapp | 02_deployment
# deployment_path="${layer_path}/02_deployment"
# output=$(az deployment group create --resource-group "${resource_group_name}" --template-file "${deployment_path}/main.bicep" --parameters "@parameters.${enviroment}.json" "@${deployment_path}/parameters.${enviroment}.json" catalogDbConnectionString="${catalogdb_cs}" identityDbConnectionString="${identitydb_cs}")