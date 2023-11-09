#!/bin/bash

source ./iac.bicep.sh
source ../utilities/os.sh

azlogin "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" 'AzureCloud'

pushd .

# in case ENVIRONMENT_DIRECTORY is empty, we set it to ENVIRONMENT_NAME (for backwards compatibility)
if [[ -z "${ENVIRONMENT_DIRECTORY}" ]]; then
  ENVIRONMENT_DIRECTORY="${ENVIRONMENT_NAME}"
fi

cd "${WORKSPACE_PATH}/IAC/Bicep/bicep"

SAVEIFS=${IFS}
IFS=$'\n'
modules=($(find . -type f -name 'main.bicep' | sort -u))
IFS=${SAVEIFS}

for deployment in "${modules[@]}"; do
  SANITIZED_EXCLUDED_FOLDERS=",${EXCLUDED_FOLDERS},"
  SANITIZED_EXCLUDED_FOLDERS=${SANITIZED_EXCLUDED_FOLDERS//;/,}

  dirname=$(dirname "${deployment}")
  sanitized_dirname=${dirname//.\//}

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

  _information "Executing Bicep validate: ${deployment}"

  path=$(dirname "${deployment}")
  export layerName=$(basename "$(dirname "$(dirname "${deployment}")")")

  params=()
  SAVEIFS=${IFS}
  IFS=$'\n'
  param_tmp_deployment="${WORKSPACE_PATH}/env/bicep/${ENVIRONMENT_DIRECTORY}/${path//.\//}/"
  if [[ -d "${param_tmp_deployment}" ]]; then
    params+=($(find "${param_tmp_deployment}" -maxdepth 1 -type f -name '*parameters*.bicepparam'))
  fi
  IFS=${SAVEIFS}

  layer_folder_path=$(dirname "${deployment}")
  if [ -f "${layer_folder_path}/_events.sh" ]; then
    source "${layer_folder_path}/_events.sh"
  fi

  if [ "$(type -t pre_validate)" == "function" ]; then
    pre_validate
  fi

  az bicep upgrade
  az config set bicep.check_version=False

  load_dotenv

  uniquer=$(echo $RANDOM | md5sum | head -c 6)
  output=$(validate "${deployment}" "${params[0]}" "${RUN_ID}" "${LOCATION_NAME}" "rg${uniquer}validate" "${layerName}")
  exit_code=$?

  if [[ ${exit_code} != 0 ]]; then
    _error "Bicep validate failed - returned code ${exit_code}"
    exit ${exit_code}
  fi

  if [ "$(type -t post_validate)" == "function" ]; then
    post_validate
  fi
  unset -f pre_validate
  unset -f post_validate

  bicep_output_to_env "${output}"

  echo "------------------------"
done

popd
