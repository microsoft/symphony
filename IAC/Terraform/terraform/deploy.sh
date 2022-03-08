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
