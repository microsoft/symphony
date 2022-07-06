#!/bin/bash

source ./iac.tf.sh
pushd .
cd ${WORKSPACE_PATH}/IAC/Terraform/terraform
modules=$(find . -type d | sort | awk '$0 !~ last "/" {print last} {last=$0} END {print last}')

SAVEIFS=$IFS
IFS=$'\n'
array=($modules)
IFS=$SAVEIFS
len=${#array[@]}
echo "Az login"
azlogin "${SUBID}" "${TENANTID}" "${CLIENTID}" "${CLIENTSECRET}" 'AzureCloud'
for deployment in "${array[@]}"
do
    if [[ ${deployment} != *"01_init"* ]]; then
    echo "tf init ${deployment}"
    pushd .
    cd $deployment
    init true "${ENV}${deployment}.tfstate" "${SUBID}" "${TENANTID}" "${CLIENTID}" "${CLIENTSECRET}" "${STATESTORAGEACCOUNT}" "${STATECONTAINER}" "${STATERG}"
    echo "tf init ${deployment}"
    echo "tf validate ${deployment}"
    validate
    code=$?
    if [[ $code != 0 ]]; then
        echo "terraform validate - returned code ${code}" 
        exit $code
    fi
    popd

    fi
done
popd