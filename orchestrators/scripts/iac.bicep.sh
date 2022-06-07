#!/bin/bash

# Includes
source _helpers.sh

usage() {
    _information "Usage: IAC Bicep commands helper"
    exit 1
}

_target_scope() {
    local bicep_file_path=$1

    target_scope=$(grep -oP 'targetScope\s*=\s*\K[^\s]+' ${bicep_file_path} | sed -e 's/[\"\`]//g')
    target_scope=${target_scope//\'/}

    echo "${target_scope}"
}

_bicep_parameters() {
    local bicep_file_path_array=$1
    printf -v var '\055-parameters @%s ' "${bicep_file_path_array[@]}"
    echo ${var%?}
}

lint() {
    local bicep_file_path=$1

    _information "Execute Bicep lint"
    az bicep build --file ${bicep_file_path}

    _information "Execute Bicep ARM-TTK"
    # TODO (enpolat): Test-AzTemplate.sh ${bicep_file_path}
}

validate() {
    local bicep_file_path=$1
    local bicep_parameters_file_path_array=$2
    local deployment_id=$3
    local location=$4
    local optional_args=$5 # --management-group-id or --resource-group

    _information "Execute Bicep validate"

    target_scope=$(_target_scope "${bicep_file_path}")
    bicep_parameters=$(_bicep_parameters ${bicep_parameters_file_path_array})

    if [[ "${target_scope}" == "managementGroup" ]]; then
        az deployment mg validate --management-group-id "${optional_args}" --name "${deployment_id}" --location "${location}" --template-file "${bicep_file_path}" "${bicep_parameters}"
    elif [[ "${target_scope}" == "subscription" ]]; then
        _information "az deployment sub validate --name ${deployment_id} --location ${location} --template-file ${bicep_file_path} ${bicep_parameters}"
        az deployment sub validate --name "${deployment_id}" --location "${location}" --template-file "${bicep_file_path}" "${bicep_parameters}"
    elif [[ "${target_scope}" == "tenant" ]]; then
        az deployment tenant validate --name "${deployment_id}" --location "${location}" --template-file "${bicep_file_path}" "${bicep_parameters}"
    else
        _information "az deployment group validate --name ${deployment_id} --resource-group ${optional_args} --template-file ${bicep_file_path} ${bicep_parameters}"
        az group create --resource-group "${optional_args}" --location "${location}"
        az deployment group validate --resource-group "${optional_args}" --name "${deployment_id}" --template-file "${bicep_file_path}" "${bicep_parameters}"
        az group delete --resource-group "${optional_args}" --yes --no-wait
    fi

    return $?
}

preview() {
    local bicep_file_path=$1
    local bicep_parameters_file_path=$2
    local deployment_id=$3
    local location=$4
    local optional_args=$5 # --management-group-id or --resource-group

    _information "Execute Bicep preview"

    target_scope=$(_target_scope "${bicep_file_path}")

    if [[ "${target_scope}" == "managementGroup" ]]; then
        az deployment mg what-if --management-group-id "${optional_args}" --location "${location}" --name "${deployment_id}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    elif [[ "${target_scope}" == "subscription" ]]; then
        az deployment sub what-if --location "${location}" --name "${deployment_id}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    elif [[ "${target_scope}" == "tenant" ]]; then
        az deployment tenant what-if --location "${location}" --name "${deployment_id}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    else
        az deployment group what-if --name "${deployment_id}" --resource-group "${optional_args}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    fi

    return $?
}

deploy() {
    local bicep_file_path=$1
    local bicep_parameters_file_path=$2
    local deployment_id=$3
    local location=$4
    local optional_args=$5 # --management-group-id or --resource-group

    _information "Execute Bicep deploy"

    target_scope=$(_target_scope "${bicep_file_path}")

    if [[ "${target_scope}" == "managementGroup" ]]; then
        az deployment mg create --management-group-id "${optional_args}" --location "${location}" --name "${deployment_id}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    elif [[ "${target_scope}" == "subscription" ]]; then
        az deployment sub create --location "${location}" --name "${deployment_id}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    elif [[ "${target_scope}" == "tenant" ]]; then
        az deployment tenant create --location "${location}" --name "${deployment_id}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    else
        az deployment group create --name "${deployment_id}" --resource-group "${optional_args}" --template-file "${bicep_file_path}" --parameters "@${bicep_parameters_file_path}"
    fi

    return $?
}
