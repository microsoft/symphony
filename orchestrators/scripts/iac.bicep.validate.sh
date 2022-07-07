#!/bin/bash

source ./iac.bicep.sh
#azlogin "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" 'AzureCloud'

pushd .

cd "${WORKSPACE_PATH}/IAC/Bicep/bicep"

SAVEIFS=${IFS}
IFS=$'\n'
modules=($(find . -type f -name 'main.bicep' | sort -u))
IFS=${SAVEIFS}

for deployment in "${modules[@]}"; do
    _information "Executing Bicep validate: ${deployment}"

    path=$(dirname "${deployment}")

    params=()
    SAVEIFS=${IFS}
    IFS=$'\n'
    params=($(find "${WORKSPACE_PATH}/env/bicep/${ENVIRONMENT}" -maxdepth 1 -type f -name '*parameters*.json'))
    param_tmp_deployment="${WORKSPACE_PATH}/env/bicep/${ENVIRONMENT}/${path//.\//}/"
echo "param_tmp_deployment:${param_tmp_deployment}"
    if [[ -d "${param_tmp_deployment}" ]]; then
        params+=($(find "${param_tmp_deployment}" -maxdepth 1 -type f -name '*parameters*.json'))
    fi
    IFS=${SAVEIFS}
echo "params:${params}"
    params_path=()
    for param_path_tmp in "${params[@]}"; do
        if [[ -f "${param_path_tmp}" ]]; then
echo "param_path_tmp:${param_path_tmp}"
            parse_bicep_parameters "${param_path_tmp}"
            params_path+=("${param_path_tmp}")
echo "params_path:${params_path}"
        fi
    done
echo "params_path:${params_path}"

    load_dotenv

    uniquer=$(echo $RANDOM | md5sum | head -c 6)
    output=$(validate "${deployment}" params_path "${RUN_ID}" "${LOCATION}" "rg${uniquer}validate")
    exit_code=$?

    if [[ ${exit_code} != 0 ]]; then
        _error "Bicep validate failed - returned code ${exit_code}"
        exit ${exit_code}
    fi

    bicep_output_to_env "${output}"

    echo "------------------------"
done

popd
