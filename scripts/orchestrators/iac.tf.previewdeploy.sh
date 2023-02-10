#!/bin/bash

source ./iac.tf.sh
pushd ${WORKSPACE_PATH}/IAC/Terraform/terraform
modules=$(find . -type d | sort | awk '$0 !~ last "/" {print last} {last=$0} END {print last}')

SAVEIFS=$IFS
IFS=$'\n'
array=($modules)
IFS=$SAVEIFS
len=${#array[@]}
echo "Az login"
azlogin "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" 'AzureCloud'
for deployment in "${array[@]}"; do
    if [[ ${deployment} != *"01_init"* ]]; then
        echo "tf init ${deployment}"
        pushd $deployment
        init true "${ENVIRONMENT_NAME}${deployment}.tfstate" "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" "${STATE_STORAGE_ACCOUNT}" "${STATE_CONTAINER}" "${STATE_RG}"
        # Preview deployment
        envfile=${deployment/'./'/''}
        envfile=${envfile/'/'/'_'}

        layer_folder_path=$(dirname "${deployment}")
        if [ -f "${layer_folder_path}/_events.sh" ]; then
        source "${layer_folder_path}/_events.sh"
        fi

        if [ "$(type -t pre_deploy)" == "function" ]; then
            pre_deploy
        fi

        preview "terraform.tfplan" "${WORKSPACE_PATH}/env/terraform/${ENVIRONMENT_NAME}/${envfile}.tfvars.json"
        code=$?

        if [[ $code != 0 ]]; then
            echo "terraform plan - returned code ${code}"
            exit $code
        fi

        # Check for resources destruction
        detect_destroy "terraform.tfplan"
        # Apply deployment
        deploy "terraform.tfplan"
        code=$?
        if [[ $code != 0 ]]; then
            echo "terraform apply - returned code ${code}"
            exit $code
        fi

        if [ "$(type -t post_deploy)" == "function" ]; then
            post_deploy
        fi
        unset -f pre_deploy
        unset -f post_deploy

        popd

    fi
done
popd
