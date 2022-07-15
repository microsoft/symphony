#!/bin/bash

declare environment="dev"

# 01_init
layer_path="01_init"
pushd "${layer_path}"
tfvar_file_path="../../../../../env/terraform/${environment}/01_init.tfvars.json"

terraform init
terraform plan -var-file="${tfvar_file_path}" -state="${environment}.tfstate" -out="${environment}.tfplan"
terraform apply -state="${environment}.tfstate" -auto-approve "${environment}.tfplan"

tfstate_tfvars=$(cat "${tfvar_file_path}")
TFSTATE_RESOURCES_GROUP_NAME=$(echo ${tfstate_tfvars} | jq -r -c '.resource_group_name')
TFSTATE_STORAGE_ACCOUNT_NAME=$(echo ${tfstate_tfvars} | jq -r -c '.storage_account_name')
TFSTATE_STORAGE_CONTAINER_NAME=$(echo ${tfstate_tfvars} | jq -r -c '.container_name')
popd

# 02_sql
layer_path="02_sql"
deployment_path="${layer_path}/01_deployment"
TFSTATE_KEY="02_sql/01_deployment.tfstate"
pushd "${deployment_path}"
tfvar_file_path="../../../../env/terraform/${environment}/02_sql_01_deployment.tfvars.json"
terraform init -migrate-state -backend-config=storage_account_name="${TFSTATE_STORAGE_ACCOUNT_NAME}" -backend-config=container_name="${TFSTATE_STORAGE_CONTAINER_NAME}" -backend-config=key="${TFSTATE_KEY}" -backend-config=resource_group_name="${TFSTATE_RESOURCES_GROUP_NAME}"
terraform plan -var-file="${tfvar_file_path}" -out="${environment}.tfplan"
terraform apply -auto-approve "${environment}.tfplan"
popd

# 02_webapp
layer_path="03_webapp"
deployment_path="${layer_path}/01_deployment"
TFSTATE_KEY="03_webapp/01_deployment.tfstate"
pushd "${deployment_path}"
tfvar_file_path="../../../../env/terraform/${environment}/03_webapp_01_deployment.tfvars.json"
terraform init -migrate-state -backend-config=storage_account_name="${TFSTATE_STORAGE_ACCOUNT_NAME}" -backend-config=container_name="${TFSTATE_STORAGE_CONTAINER_NAME}" -backend-config=key="${TFSTATE_KEY}" -backend-config=resource_group_name="${TFSTATE_RESOURCES_GROUP_NAME}"
terraform plan -var-file="${tfvar_file_path}" -out="${environment}.plan"
terraform apply -auto-approve "${environment}.plan"
popd
