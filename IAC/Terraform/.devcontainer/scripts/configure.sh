#!/usr/bin/env bash

_error() {
    printf "\e[31mERROR: $@\n\e[0m"
}

_debug() {
    #Only print debug lines if debugging is turned on.
    if [ "$DEBUG_FLAG" == true ]; then
        msg="$@"
        LIGHT_CYAN='\033[0;35m'
        NC='\033[0m'
        printf "DEBUG: ${NC} %s ${NC}\n" "${msg}"
    fi
}

_debug_json() {
    if [ "$DEBUG_FLAG" == true ]; then
        echo $1 | jq
    fi
}

_information() {
    printf "\e[36m$@\n\e[0m"
}

_success() {
    printf "\e[32m$@\n\e[0m"
}

#Script Parameters (Required)
declare DEBUG_FLAG=false
declare TF_SP_MODE=false
declare SP_RAW=''
declare SP_SUBSCRIPTION_NAME=''
declare SP_ID=''
declare SP_SUBSCRIPTION_ID=''
declare SP_SECRET=''
declare SP_TENANT_ID=''
declare STORAGE_ACCOUNT_NAME=''

# Initialize parameters specified from command line
while [[ "$#" -gt 0 ]]
do
  case $1 in
    -h | --help)
        usage
        exit 0
        ;;
     --storageAccount )                
        STORAGE_ACCOUNT_NAME=$2
        ;;         

    -s | --servicePrincipal )   
        SP_RAW=$2
        ;;
    -d | --debug )             
        DEBUG_FLAG=true
        ;; 
    -t | --tfSpModeOnly )             
        TF_SP_MODE=true
        ;;         
  esac
  shift
done

parse_sp() {
    # Expected Format "SUB_NAME='<Azure Subscription Name>' SP_ID=<Service Principal ID> SP_SUBSCRIPTION_ID=<Azure Subscription ID> SP_SECRET=<Service Principal Secret> SP_TENANT_ID=<Service Principal Tenant ID>"
    # NOTE: format is with quotes ""

    _information "Parsing Service Principal credentials..."
    BFS=$IFS
    IFS=' '
    read -ra kv_pairs <<<${1}
    IFS=$BFS

    len=${#kv_pairs[@]}
    expectedLength=4

    if [ $len != $expectedLength ]; then
        _error "SP_RAW contains invalid # of parameters"
        _error "Expected Format SUB_NAME='<Azure Subscription Name>' SP_ID=<Service Principal ID> SP_SUBSCRIPTION_ID=<Azure Subscription ID> SP_SECRET=<Service Principal Secret> SP_TENANT_ID=<Service Principal Tenant ID>"
        return 1
    fi

    for kv in "${kv_pairs[@]}"; do

        BFS=$IFS
        IFS='='
        read -ra arr <<<"$kv"
        IFS=$BFS

        k=${arr[0]}
        v=${arr[1]}

        case "$k" in
        "SUB_NAME") SP_SUBSCRIPTION_NAME=$v ;;
        "SP_ID") SP_ID=$v ;;
        "SP_SUBSCRIPTION_ID") SP_SUBSCRIPTION_ID=$v ;;
        "SP_SECRET") SP_SECRET=$v ;;
        "SP_TENANT_ID") SP_TENANT_ID=$v ;;
        *)
            _error "Invalid service principal parameter."
            return 1
            ;;
        esac
    done

    _success "Sucessfully parsed service principal credentials..."
}


devcontainer_create_backend_tfvars() {
    local backendFile=~/repos/Terraform-Code/environments/dev/backend.tfvars
    touch $backendFile
    echo "storage_account_name  = \"${TF_VAR_BACKEND_STORAGE_ACCOUNT_NAME}\"" >> $backendFile
    echo "container_name        = \"tfrs\"" >> $backendFile
    echo "resource_group_name   = \"tf-remote-state-dev\"" >> $backendFile
    echo "subscription_id   = \"$SP_SUBSCRIPTION_ID\"" >> $backendFile
    echo "tenant_id         = \"$SP_TENANT_ID\""  >> $backendFile
    echo "client_id         = \"$SP_ID\"" >> $backendFile
    echo "client_secret     = \"$SP_SECRET\"" >> $backendFile
   _success "Sucessfully created backend.tfvars in ~/repos/Terraform-Code/environments/dev/backend.tfvars"
}

remove_override_tf() {
    local DEPLOYMENTS
    pushd ~/repos/$AZDO_PROJECT_NAME/Terraform-Code/terraform
        DEPLOYMENTS=(`find . -type d | grep '.\/[0-9][0-9]' | cut -c 3- | grep -v '^01_init' | grep -v '.*\/modules\/.*' | grep -v '.*\/modules' | grep '.*\/.*' | sort`)
        for deployment in "${DEPLOYMENTS[@]}"
        do
            pushd $deployment
                rm _override.tf 
                cp /home/vscode/.lucidity/.envcrc-tf-remote-state ./.envrc
                direnv allow
            popd
        done    
    popd
}

devcontainer_create_arm_tfvars() {
    local armFile=/home/vscode/repos/Terraform-Code/environments/dev/arm.env
    echo "ARM_SUBSCRIPTION_ID=$SP_SUBSCRIPTION_ID" >> $armFile
    echo "ARM_TENANT_ID=$SP_TENANT_ID"  >> $armFile
    echo "ARM_CLIENT_ID=$SP_ID" >> $armFile
    echo "ARM_CLIENT_SECRET=$SP_SECRET" >> $armFile   
    _success "Sucessfully added ARM ENV VARS to $armFile"
}

# main
parse_sp "${SP_RAW}"
if [ "$TF_SP_MODE" == false ]; then
  devcontainer_create_backend_tfvars    
  remove_override_tf
fi
devcontainer_create_arm_tfvars
