#!/bin/bash

_debug_json() {
    if [ ${DEBUG_FLAG} == true ]; then
        echo "${@}" | jq
    fi
}

_debug() {
    # Only print debug lines if debugging is turned on.
    if [ ${DEBUG_FLAG} == true ]; then
        if [ -n "${GITHUB_ACTION}" ]; then
            echo "::debug::$@"
        elif [ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}" ]; then
            echo -e "##[debug]$@"
        else
            echo "DEBUG: $@"
        fi
    fi
}

_error() {
    if [ -n "${GITHUB_ACTION}" ]; then
        echo "::error::$@"
    elif [ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}" ]; then
        echo -e "##[error]$@"
    else
        echo "ERROR: $@"
    fi
}

_warning() {
    if [ -n "${GITHUB_ACTION}" ]; then
        echo "::warning::$@"
    elif [ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}" ]; then
        echo -e "##[warning]$@"
    else
        echo "WARNING: $@"
    fi
}

_information() {
    if [ -n "${GITHUB_ACTION}" ]; then
        echo "::notice::$@"
    elif [ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}" ]; then
        echo -e "##[command]$@"
    else
        echo "NOTICE: $@"
    fi
}

_success() {
    if [ -n "${GITHUB_ACTION}" ]; then
        echo "::notice::$@"
    elif [ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}" ]; then
        echo -e "##[section]$@"
    else
        echo "NOTICE: $@"
    fi
}

azlogin() {
    local subscription_id="${1}"
    local tenant_id="${2}"
    local client_id="${3}"
    local client_secret="${4}"
    local cloud_name="${5}"

    # AzureCloud AzureChinaCloud AzureUSGovernment AzureGermanCloud
    az cloud set --name "${cloud_name}"
    az login --service-principal --username="${client_id}" --password="${client_secret}" --tenant="${tenant_id}"
    az account set --subscription "${subscription_id}"

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

load_dotenv() {
    local dotenv_file_path="${1:-".env"}"

    if [[ -f "${dotenv_file_path}" ]]; then
        _information "Loading .env file: ${dotenv_file_path}"
        set -o allexport
        source "${dotenv_file_path}"
        set +o allexport
    fi
}
