#!/bin/bash

# Includes
source _helpers.sh

environment="__ENVIRONMENT__"
subscription_id="__SUBSCRIPTION_ID__"
tenant_id="__TENANT_ID__"
layers="__LAYERS__"
deployments="__DEPLOYMENTS__"

usage() {
    _information "Usage: IAC terraform commands helper"
    exit 1
}

init() {
    backend_config=$1
    key=$2
    subscription_id=$3
    tenant_id=$4
    client_id=$5
    client_secret=$6
    storage_account_name=${TF_VAR_BACKEND_STORAGE_ACCOUNT_NAME}
    container_name=${TF_VAR_BACKEND_CONTAINER_NAME}
    resource_group_name=${TF_VAR_BACKEND_RESOURCE_GROUP_NAME}

    if [ "${backend_config}" == "false" ]; then
        _information "Execute terraform init"
        terraform init
    else
        _information "Execute terraform init with backend-config"
        terraform init \
            -backend-config=storage_account_name=${storage_account_name} \
            -backend-config=container_name=${container_name} \
            -backend-config=key=${key} \
            -backend-config=resource_group_name=${resource_group_name} \
            -backend-config=subscription_id=${subscription_id} \
            -backend-config=tenant_id=${tenant_id} \
            -backend-config=client_id=${client_id} \
            -backend-config=client_secret=${client_secret} \
            -reconfigure
    fi
}

format() {
    _information "Execute terraform fmt"
    terraform fmt
    exit $?
}

validate() {
    _information "Execute terraform validate"
    terraform validate
    exit $?
}

preview() {
    plan_file_name=$1
    var_file=$2

    _information "Execute terraform plan"
    if [[ -z "$2" ]]; then
        echo "terraform plan -input=false -out=${plan_file_name}"
        terraform plan -input=false -out=${plan_file_name}
    else
        echo "terraform plan -input=false -out=${plan_file_name} -var-file=${var_file}"
        terraform plan -input=false -out=${plan_file_name} -var-file=${var_file}
    fi

    exit $?
}

deploy() {
    plan_file_name=$1

    _information "Execute terraform apply"
    terraform apply -input=false -auto-approve ${plan_file_name}

    exit $?
}

destroy() {
    _information "Execute terraform destroy"
    terraform destroy -input=false -auto-approve

    exit $?
}

detect_destroy() {
    plan_file_name=$1
    _information "Detect destroy in .tfplan file"

    terraform show -no-color -json ${plan_file_name} >mytmp.json
    actions=$(cat mytmp.json | jq '.resource_changes[].change.actions[]' | grep 'delete')

    if [[ -z $actions ]]; then
        _information "Plan file ${plan_file_name} has not delete changes"
    else
        _information "Plan file ${plan_file_name} has delete changes"
    fi

    exit $?
}

lint() {
    _information "Execute tflint"

    lint_res_file_name="$(basename $PWD)_lint_res.xml"
    filePath=$(echo "${lint_res_file_name}" | sed -e 's/\//-/g')

    "tflint" >$filePath 2>&1

    if [[ -z $(grep '[^[:space:]]' $filePath) ]]; then
        echo "tflint passed"
        exit 0
    else
        echo "tflint failed. lint results in file name ${lint_res_file_name}"
        sed -i 's/\x1b\[[0-9;]*m//g' $filePath
        cat $filePath
        exit 1
    fi
}
