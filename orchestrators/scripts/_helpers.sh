_debug_json() {
    if [ ${DEBUG_FLAG} == true ]; then
        echo "${@}" | jq
    fi
}

_debug() {
    # Only print debug lines if debugging is turned on.
    if [ ${DEBUG_FLAG} == true ]; then
        _color="\e[35m" # magenta
        echo -e "${_color}##[debug] $@\n\e[0m" 2>&1
    fi
}

_error() {
    _color="\e[31m" # red
    echo -e "${_color}##[error] $@\n\e[0m" 2>&1
}

_warning() {
    _color="\e[33m" # yellow
    echo -e "${_color}##[warning] $@\n\e[0m" 2>&1
}

_information() {
    _color="\e[36m" # cyan
    echo -e "${_color}##[command] $@\n\e[0m" 2>&1
}

_success() {
    _color="\e[32m" # green
    echo -e "${_color}##[command] $@\n\e[0m" 2>&1
}

azlogin() {
    subscription_id=$1
    tenant_id=$2
    client_id=$3
    client_secret=$4
    cloud_name=$5

    # AzureCloud AzureChinaCloud AzureUSGovernment AzureGermanCloud
    az cloud set --name ${cloud_name}
    az login --service-principal --username ${client_id} --password ${client_secret} --tenant ${tenant_id}
    az account set --subscription ${subscription_id}

    export ARM_CLIENT_ID="${client_id}"
    export ARM_CLIENT_SECRET="${client_secret}"
    export ARM_SUBSCRIPTION_ID="${subscription_id}"
    export ARM_TENANT_ID="${tenant_id}"

    # https://www.terraform.io/docs/providers/azurerm/index.html#environment
    # environment - (Optional) The Cloud Environment which should be used. 
    # Possible values are public, usgovernment, german, and china. Defaults to public. 
    # This can also be sourced from the ARM_ENVIRONMENT environment variable.

    if [ "${cloud_name}" == 'AzureCloud' ]; then
        export ARM_ENVIRONMENT="public"
    elif [ "${cloud_name}" == 'AzureUSGovernment' ]; then
        export ARM_ENVIRONMENT="usgovernment"
    elif [ "${cloud_name}" == 'AzureChinaCloud' ]; then 
        export ARM_ENVIRONMENT="usgovernment" 
    elif [ "${cloud_name}" == 'AzureGermanCloud' ]; then
        export ARM_ENVIRONMENT="german" 
    else
        _error "Unknown cloud. Check documentation https://www.terraform.io/docs/providers/azurerm/index.html#environment"
        return 1
    fi
}
