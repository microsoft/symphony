#!/bin/bash

source ./iac.bicep.sh
source ../utilities/os.sh

azlogin "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" 'AzureCloud'

pushd .

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
    params=($(find "${WORKSPACE_PATH}/env/bicep/${ENVIRONMENT_NAME}" -maxdepth 1 -type f -name '*parameters*.json'))
    param_tmp_deployment="${WORKSPACE_PATH}/env/bicep/${ENVIRONMENT_NAME}/${path//.\//}/"
    if [[ -d "${param_tmp_deployment}" ]]; then
        params+=($(find "${param_tmp_deployment}" -maxdepth 1 -type f -name '*parameters*.json'))
    fi
    IFS=${SAVEIFS}

    params_path=()
    for param_path_tmp in "${params[@]}"; do
        if [[ -f "${param_path_tmp}" ]]; then
            parse_bicep_parameters "${param_path_tmp}"
            params_path+=("${param_path_tmp}")
        fi
    done

    load_dotenv

    uniquer=$(echo $RANDOM | md5sum | head -c 6)
    output=$(validate "${deployment}" params_path "${RUN_ID}" "${LOCATION_NAME}" "rg${uniquer}validate" "${layerName}")
    exit_code=$?

    if [[ ${exit_code} != 0 ]]; then
        _error "Bicep validate failed - returned code ${exit_code}"
        exit ${exit_code}
    fi

    bicep_output_to_env "${output}"

    echo "------------------------"
done

popd
