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

parse_bicep_parameters() {
    bicep_parameters_file_path=$1

    parameters_file=$(cat ${bicep_parameters_file_path})
    # parameters_to_parse=$(echo ${parameters_file} | jq -r '.parameters | to_entries[] | select (.value.value == "PLACEHOLDER") | .key')

    #test
    # export sqlServerAdministratorLogin="sa"
    # export sqlServerAdministratorPassword="sa"

    # SAVEIFS=$IFS
    # IFS=$'\n'
    # parameters_to_parse=($parameters_to_parse)
    # IFS=$SAVEIFS

    # for ((i = 0; i < ${#parameters_to_parse[@]}; i++)); do
    #     if [[ ! -z "${!parameters_to_parse[$i]}" ]]; then

    #     fi
    # done

    echo "${parameters_file}" | jq '.parameters 
    |= map_values(if .value | (startswith("$") and env[.[1:]]) 
                  then .value |= env[.[1:]] else . end)' >${bicep_parameters_file_path}
}

# test
#parse_bicep_parameters env/bicep/dev/01_sql/02_deployment/parameters.json
