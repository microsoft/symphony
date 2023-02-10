#!/bin/bash

source ./iac.bicep.sh
azlogin "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" 'AzureCloud'

pushd .

cd "${WORKSPACE_PATH}/IAC/Bicep/bicep" || exit

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

    _information "Preparing for ${deployment}"

    path=$(dirname "${deployment}")
    export layerName=$(basename "$(dirname "$(dirname "${deployment}")")")

    params=()
    SAVEIFS=${IFS}
    IFS=$'\n'
    params=($(find "${WORKSPACE_PATH}/env/bicep/${ENVIRONMENT_NAME}" -maxdepth 1 -type f -name '*parameters*.json'))
    param_tmp_deployment="${WORKSPACE_PATH}/env/bicep/${ENVIRONMENT_NAME}/${path//.\//}/"
    if [[ -d "${param_tmp_deployment}" ]]; then
        params+=($(find "${param_tmp_deployment}" -maxdepth 1 -type f -name '*parameters*.json' -and -not -name '*mockup*'))
    fi
    IFS=${SAVEIFS}

    layer_folder_path=$(dirname "${deployment}")
    if [ -f "${layer_folder_path}/_events.sh" ]; then
      source "${layer_folder_path}/_events.sh"
    fi

    if [ "$(type -t pre_deploy)" == "function" ]; then
        pre_deploy
    fi

    params_path=()
    for param_path_tmp in "${params[@]}"; do
        if [[ -f "${param_path_tmp}" ]]; then
            parse_bicep_parameters "${param_path_tmp}"
            params_path+=("${param_path_tmp}")
        fi
    done
    load_dotenv

    # resourceGroupName is a bicep output that is stored in an environment variable.
    _information "Executing Bicep preview: 'preview \"${deployment}\" params_path \"${RUN_ID}\" \"${LOCATION_NAME}\" \"${resourceGroupName}\"'"
   
    output=$(preview "${deployment}" params_path "${RUN_ID}" "${LOCATION_NAME}" "${resourceGroupName}")
  
    exit_code=$?

    if [[ ${exit_code} != 0 ]]; then
        _error "Bicep preview failed - returned code ${exit_code}"
        exit ${exit_code}
    fi

    if [ "$(type -t post_deploy)" == "function" ]; then
        post_deploy
    fi
    unset -f pre_deploy
    unset -f post_deploy

    _information "Executing Bicep deploy: 'deploy \"${deployment}\" params_path \"${RUN_ID}\" \"${LOCATION_NAME}\" \"${resourceGroupName}\"'"

    output=$(deploy "${deployment}" params_path "${RUN_ID}" "${LOCATION_NAME}" "${resourceGroupName}")

    exit_code=$?

    if [[ ${exit_code} != 0 ]]; then
        _error "Bicep deploy failed - returned code ${exit_code}"
        exit ${exit_code}
    fi

    bicep_output_to_env "${output}" ".env" "false" "true"
done

popd || exit
