#!/bin/bash

source ./iac.tf.sh
pushd "${WORKSPACE_PATH}/IAC/Terraform/terraform"
modules=$(find . -type d  -not -path "*.terraform*" | sort | awk '$0 !~ last "/" {print last} {last=$0} END {print last}')
#modules=($(find . -type f -name '*.tf' | sort -u))
terraform_absolute_path="${WORKSPACE_PATH}/IAC/Terraform/terraform"
SAVEIFS=$IFS
IFS=$'\n'
array=($modules)
IFS=$SAVEIFS
len=${#array[@]}

get_directory_name(){
    path=$1
    pushd $path >/dev/null 2>&1
        files=(*)        
        dirname=$(dirname "$path/${files[0]}")
        sanitized_dirname=${dirname//.\//}
    popd >/dev/null 2>&1
    echo "$sanitized_dirname"
}

azlogin "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" 'AzureCloud'
for deployment in "${array[@]}"; do
    SANITIZED_EXCLUDED_FOLDERS=",${EXCLUDED_FOLDERS},"
    SANITIZED_EXCLUDED_FOLDERS=${SANITIZED_EXCLUDED_FOLDERS//;/,}

    sanitized_dirname=$(get_directory_name "$deployment") 
    echo "sanitized_dirname=$sanitized_dirname"
    if [[ ${sanitized_dirname} == __* ]]; then
        _information "Skipping ${deployment}"
        echo ""
        echo "------------------------"
        continue
    fi

    if [[ ${SANITIZED_EXCLUDED_FOLDERS} == *",${sanitized_dirname},"* ]]; then
        _information "${sanitized_dirname} excluded"
        echo ""
        echo "------------------------"
        continue
    fi
    deployment=${deployment/'./'/"${terraform_absolute_path}/"}

    if [[ ${deployment} != *"01_init"* ]]; then
        _information "Executing tf validate for: ${deployment}"
        echo "tf init ${deployment}"
        pushd $deployment >/dev/null 2>&1

        init true "${ENVIRONMENT_NAME}${deployment}.tfstate" "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" "${STATE_STORAGE_ACCOUNT}" "${STATE_CONTAINER}" "${STATE_RG}"
        echo "tf init ${deployment}"
        echo "tf validate ${deployment}"
        validate
        code=$?
        if [[ $code != 0 ]]; then
            echo "terraform validate - returned code ${code}"
            exit $code
        fi
        popd >/dev/null 2>&1

    fi
done
popd
