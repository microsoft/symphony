#!/bin/bash
set -e

# Includes
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

source "$SCRIPT_DIR"/_helpers.sh
source "$SCRIPT_DIR"/../utilities/os.sh

usage() {
  _information "Usage: IAC Bicep commands helper"
  exit 1
}

_target_scope() {
  local bicep_file_path="${1}"

  check_mac_os
  is_mac=$?

  # The default grep command behaves differently on macos
  # please ensure ggrep is installed https://formulae.brew.sh/formula/grep#default
  if [[ $is_mac == 0 ]]; then
    target_scope=$(ggrep -oP 'targetScope\s*=\s*\K[^\s]+' "${bicep_file_path}" | sed -e 's/[\"\`]//g')
  else
    target_scope=$(grep -oP 'targetScope\s*=\s*\K[^\s]+' "${bicep_file_path}" | sed -e 's/[\"\`]//g')
  fi

  target_scope=${target_scope//\'/}

  echo "${target_scope}"
}

_bicep_parameters() {
  local bicep_file_path_array_tmp=$1[@]
  local bicep_file_path_array=("${!bicep_file_path_array_tmp}")

  printf -v var '@%s ' "${bicep_file_path_array[@]}"
  params="${var%?}"

  if [ -n "${params}" ]; then
    echo "--parameters ${params}"
  fi
}

parse_bicep_parameters() {
  local bicep_parameters_file_path="${1}"
  local bicep_parameters_json='./generatedparam.json'
  bicep build-params $bicep_parameters_file_path --outfile $bicep_parameters_json
  local content=$(cat $bicep_parameters_json)

  while IFS='=' read -r key value; do
    content=${content//"\$${key}"/$value}
  done < <(env)

  echo -e "${content}" >|"${bicep_parameters_file_path}"
}

bicep_output_to_env() {
  local bicep_output_json="${1}"
  local dotenv_file_path="${2:-".env"}"
  local saveDeployOutput="${3:-"false"}"
  local keepEnvFile="${4:-"false"}"

  if [ "$keepEnvFile" == "false" ]; then
    if [[ -f "${dotenv_file_path}" ]]; then
      rm -f "${dotenv_file_path}"
    fi
  fi

  if [ "$saveDeployOutput" == "true" ]; then
    if [ -n "${GITHUB_ACTION}" ]; then
      echo "bicepOutputJson=\"${bicep_output_json}\"" >>$GITHUB_OUTPUT
    elif [ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}" ]; then
      local bicepOutput="$(echo ${bicep_output_json} | jq -c)"
      echo "##vso[task.setvariable variable=bicepJson;isOutput=true]${bicepOutput}"
    fi
  fi

  echo "${bicep_output_json}" | jq -c 'select(.properties.outputs | length > 0) | .properties.outputs | to_entries[] | [.key, .value.value]' |
    while IFS=$'\n' read -r c; do

      outputName=$(echo "$c" | jq -r '.[0]')
      outputValue=$(echo "$c" | jq -r '.[1]')

      echo "${outputName}"="${outputValue}" >>"${dotenv_file_path}"
      eval export "${outputName}"="${outputValue}"

      if [ -n "${GITHUB_ACTION}" ]; then
        echo "{${outputName}}={${outputValue}}" >>$GITHUB_ENV
      elif [ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}" ]; then
        echo "##vso[task.setvariable variable=${outputName};isOutput=true]${outputValue}"
      fi
    done

  exit_code=${PIPESTATUS[1]}
  if [[ $exit_code != 0 ]]; then
    _error "Bicep validate failed, bicep_output_to_env  - returned code ${exit_code}"
    exit "$exit_code"
  fi
}

lint() {
  local bicep_file_path=$1

  output=$(az bicep build --file "${bicep_file_path}")
  exit_code=$?

  echo "${output}"

  return ${exit_code}
}
export -f lint

validate() {
  local bicep_file_path=$1
  local bicep_parameters=$2
  local deployment_id=$3
  local location=$4
  local optional_args=$5 # --management-group-id or --resource-group
  export layerName=$6

  target_scope=$(_target_scope "${bicep_file_path}")
  if [[ "${target_scope}" == "managementGroup" ]]; then
    command="az deployment mg validate --management-group-id ${optional_args} --name ${deployment_id} --location ${LOCATION_NAME} --template-file ${bicep_file_path} --parameters ${bicep_parameters}"
    output=$(eval "${command}")
    exit_code=$?
  elif [[ "${target_scope}" == "subscription" ]]; then
    command="az deployment sub validate --name ${deployment_id} --location ${LOCATION_NAME} --template-file ${bicep_file_path} --parameters ${bicep_parameters}"
    output=$(eval "${command}")
    exit_code=$?
  elif [[ "${target_scope}" == "tenant" ]]; then
    command="az deployment tenant validate --name ${deployment_id} --location ${LOCATION_NAME} --template-file ${bicep_file_path} --parameters ${bicep_parameters}"
    output=$(eval "${command}")
    exit_code=$?
  else
    command="az deployment group validate --name ${deployment_id} --resource-group ${optional_args} --template-file ${bicep_file_path} --parameters ${bicep_parameters}"
    az group create --resource-group "${optional_args}" --location "${LOCATION_NAME}"
    output=$(eval "${command}")
    exit_code=$?
    az group delete --resource-group "${optional_args}" --yes
  fi

  echo "${output}"

  return ${exit_code}
}
export -f validate

preview() {
  local bicep_file_path=$1
  local bicep_parameters=$2
  local deployment_id=$3
  local location=$4
  local optional_args=$5 # --management-group-id or --resource-group

  target_scope=$(_target_scope "${bicep_file_path}")

  if [[ "${target_scope}" == "managementGroup" ]]; then
    command="az deployment mg what-if --no-pretty-print --management-group-id ${optional_args} --name ${deployment_id} --location ${LOCATION_NAME} --template-file ${bicep_file_path} --parameters ${bicep_parameters}"
  elif [[ "${target_scope}" == "subscription" ]]; then
    command="az deployment sub what-if --no-pretty-print --name ${deployment_id} --location ${LOCATION_NAME} --template-file ${bicep_file_path} --parameters ${bicep_parameters}"
  elif [[ "${target_scope}" == "tenant" ]]; then
    command="az deployment tenant what-if --no-pretty-print --name ${deployment_id} --location ${LOCATION_NAME} --template-file ${bicep_file_path} --parameters ${bicep_parameters}"
  else
    command="az deployment group what-if --no-pretty-print --name ${deployment_id} --resource-group ${optional_args} --template-file ${bicep_file_path} --parameters ${bicep_parameters}"
  fi

  output=$(eval "${command}")
  exit_code=$?

  echo "${output}"

  return ${exit_code}
}
export -f preview

deploy() {
  local bicep_file_path=$1
  local bicep_parameters=$2
  local deployment_id=$3
  local location=$4
  local optional_args=$5 # --management-group-id or --resource-group

  target_scope=$(_target_scope "${bicep_file_path}")

  if [[ "${target_scope}" == "managementGroup" ]]; then
    command="az deployment mg create --management-group-id ${optional_args} --name ${deployment_id} --location ${LOCATION_NAME} --template-file ${bicep_file_path} --parameters ${bicep_parameters}"
  elif [[ "${target_scope}" == "subscription" ]]; then
    command="az deployment sub create --name ${deployment_id} --location ${LOCATION_NAME} --template-file ${bicep_file_path} --parameters ${bicep_parameters}"
  elif [[ "${target_scope}" == "tenant" ]]; then
    command="az deployment tenant create --name ${deployment_id} --location ${LOCATION_NAME} --template-file ${bicep_file_path} --parameters ${bicep_parameters}"
  else
    command="az deployment group create --name ${deployment_id} --resource-group ${optional_args} --template-file ${bicep_file_path} --parameters ${bicep_parameters}"
  fi

  output=$(eval "${command}")
  exit_code=$?

  echo "${output}"

  return ${exit_code}
}
export -f deploy

destroy() {
  local environmentName=${1}
  local layerName=${2}
  local location=${3}

  _information "Getting resource groups..."
  resourceGroups=$(az group list --output json |
    jq -c -r ".[]
            | select(
                .location == \"${location}\" and
                .tags.GeneratedBy == \"symphony\" and
                .tags.EnvironmentName == \"${environmentName}\" and
                .tags.LayerName == \"${layerName}\")
            | @base64")

  exit_code=$?
  if [[ ${exit_code} != 0 ]]; then
    _error "Getting resource groups failed"
    return ${exit_code}
  fi

  _information "For each resource groups..."
  for b64ResourceGroup in ${resourceGroups}; do
    resourceGroupJson=$(echo "$b64ResourceGroup" | base64 --decode)
    resourceGroup=$(echo "$resourceGroupJson" | jq -r '.name')
    resourceGroupId=$(echo "$resourceGroupJson" | jq -r '.id')

    _information "Getting deployments for ${resourceGroup}..."
    deployments=$(az deployment sub list --output json |
      jq -c -r ".[]
                | select(
                    .properties.outputResources[]? | select(.id == \"${resourceGroupId}\"))
                | @base64")

    exit_code=$?
    if [[ ${exit_code} != 0 ]]; then
      _error "Getting deployments for ${resourceGroup} failed"
      return ${exit_code}
    fi

    _information "For each deployment..."
    for b64Deployment in ${deployments}; do
      deploymentJson=$(echo "$b64Deployment" | base64 --decode)
      deployment=$(echo "$deploymentJson" | jq -r '.name')

      _information "Deleting deployment : ${deployment}"
      az deployment sub delete --name "${deployment}"
      exit_code=$?
      if [[ ${exit_code} != 0 ]]; then
        _error "Deleting deployment : ${deployment} failed"
        return ${exit_code}
      fi

      deploymentNameGenerator="${deployment}NameGenerator"
      _information "Deleting deployment : ${deploymentNameGenerator}"
      az deployment sub delete --name "${deploymentNameGenerator}"
      exit_code=$?
      if [[ ${exit_code} != 0 ]]; then
        _error "Deleting deployment : ${deploymentNameGenerator} failed"
        return ${exit_code}
      fi
    done

    _information "Destroying resource group: ${resourceGroup}"
    az group delete --resource-group "${resourceGroup}" --yes
    exit_code=$?
    if [[ ${exit_code} != 0 ]]; then
      _error "Deleting Resource group : ${resourceGroup} failed"
      return ${exit_code}
    fi
    _information "Resource group destroyed: ${resourceGroup}"

  done
  return ${exit_code}
}
export -f destroy
