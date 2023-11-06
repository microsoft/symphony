#!/bin/bash

source ./iac.tf.sh
pushd "${WORKSPACE_PATH}/IAC/Terraform/terraform"
modules=$(find . -type d | sort | awk '$0 !~ last "/" {print last} {last=$0} END {print last}')

SAVEIFS=$IFS
IFS=$'\n'
array=($modules)
IFS=$SAVEIFS
len=${#array[@]}

azlogin "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" 'AzureCloud'
for deployment in "${array[@]}"; do
  if [[ ${deployment} != *"01_init"* ]]; then
    echo "tf init ${deployment}"
    pushd $deployment

    init true "${ENVIRONMENT_NAME}${deployment}.tfstate" "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" "${STATE_STORAGE_ACCOUNT}" "${STATE_CONTAINER}" "${STATE_RG}"
    echo "tf init ${deployment}"

    layer_folder_path=$(dirname "${deployment}")
    if [ -f "${layer_folder_path}/_events.sh" ]; then
      source "${layer_folder_path}/_events.sh"
    fi

    if [ "$(type -t pre_validate)" == "function" ]; then
      pre_validate
    fi

    echo "tf validate ${deployment}"
    validate
    code=$?
    if [[ $code != 0 ]]; then
      echo "terraform validate - returned code ${code}"
      exit $code
    fi
    if [ "$(type -t post_validate)" == "function" ]; then
      post_validate
    fi
    unset -f pre_validate
    unset -f post_validate

    popd

  fi
done
popd
