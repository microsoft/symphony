#!/bin/bash

echo 'Run tflint'
source ./iac.tf.sh
pushd "${WORKSPACE_PATH}/IAC/Terraform/terraform"
 
terraform_absolute_path="${WORKSPACE_PATH}/IAC/Terraform/terraform"
SAVEIFS=${IFS}
IFS=$'\n'
modules=($(find . -type d -not -path "*.terraform*" | sort | awk '$0 !~ last "/" {print last} {last=$0} END {print last}'))

for deployment in "${modules[@]}"; do
    SANITIZED_EXCLUDED_FOLDERS=",${EXCLUDED_FOLDERS},"
    SANITIZED_EXCLUDED_FOLDERS=${SANITIZED_EXCLUDED_FOLDERS//;/,}

    pushd $deployment
        files=(*)        
        dirname=$(dirname "$deployment/${files[0]}")
        sanitized_dirname=${dirname//.\//}
    popd

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
    _information "Executing tf lint for: ${deployment}"
    pushd ${deployment}
        lint
        code=$?
        if [[ $code != 0 ]]; then
            _error "tflint failed- returned code ${code}"
            exit ${code}
        fi
    popd

done
popd
