#!/bin/bash

# Includes
source _helpers.sh

usage() {
    _information "Usage: IAC Bicep commands helper"
    exit 1
}

_target_scope() {
    bicep_file_path=$1

    targetScope=$(grep -oP 'targetScope\s*=\s*\K[^\s]+' ${bicep_file_path} | sed -e 's/[\"\`]//g')
    targetScope=${targetScope//\'/}

    echo "${targetScope}"
}

lint() {
    bicep_file_path=$1

    _information "Execute Bicep lint"
    az bicep build --file ${bicep_file_path}

    _information "Execute Bicep ARM-TTK"
    # TODO (enpolat): Test-AzTemplate.sh ${bicep_file_path}
}

validate() {
    bicep_file_path=$1
    bicep_parameters_file_path=$2
    deployment_id=$3
    location=$4
    optional_parameters=$5 # --management-group-id or --resource-group

    _information "Execute Bicep validate"

    targetScope=$(_target_scope "${bicep_file_path}")

    if [[ "${targetScope}" == "managementGroup" ]]; then
        az deployment mg validate --management-group-id "${optional_parameters}" --name "${deployment_id}" --location "${location}" --template-file "${bicep_file_path}" --parameters "${bicep_parameters_file_path}"
    elif [[ "${targetScope}" == "subscription" ]]; then
        az deployment sub validate --name "${deployment_id}" --location "${location}" --template-file "${bicep_file_path}" --parameters "${bicep_parameters_file_path}"
    elif [[ "${targetScope}" == "tenant" ]]; then
        az deployment tenant validate --name "${deployment_id}" --location "${location}" --template-file "${bicep_file_path}" --parameters "${bicep_parameters_file_path}"
    else
        az deployment group validate --resource-group "${optional_parameters}" --name "${deployment_id}" --template-file "${bicep_file_path}" --parameters "${bicep_parameters_file_path}"
    fi

    return $?
}

preview() {
    bicep_file_path=$1
    bicep_parameters_file_path=$2
    deployment_id=$3
    location=$4
    optional_parameters=$5 # --management-group-id or --resource-group

    _information "Execute Bicep preview"

    targetScope=$(_target_scope "${bicep_file_path}")

    if [[ "${scope}" == "managementGroup" ]]; then
        az deployment mg what-if --management-group-id "${optional_parameters}" --location "${location}" --name "${deployment_id}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    elif [[ "${scope}" == "subscription" ]]; then
        az deployment sub what-if --location "${location}" --name "${deployment_id}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    elif [[ "${scope}" == "tenant" ]]; then
        az deployment tenant what-if --location "${location}" --name "${deployment_id}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    else
        az deployment group what-if --name "${deployment_id}" --resource-group "${optional_parameters}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    fi

    return $?
}

deploy() {
    scope=$1
    bicep_file_path=$2
    bicep_parameters_file_path=$3
    deployment_id=$4
    location=$5
    optional_parameters=$6 # --management-group-id or --resource-group

    _information "Execute Bicep deploy"

    targetScope=$(_target_scope "${bicep_file_path}")

    if [[ "${scope}" == "managementGroup" ]]; then
        az deployment mg create --management-group-id "${optional_parameters}" --location "${location}" --name "${deployment_id}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    elif [[ "${scope}" == "subscription" ]]; then
        az deployment sub create --location "${location}" --name "${deployment_id}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    elif [[ "${scope}" == "tenant" ]]; then
        az deployment tenant create --location "${location}" --name "${deployment_id}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    else
        az deployment group create --name "${deployment_id}" --resource-group "${optional_parameters}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    fi

    return $?
}
