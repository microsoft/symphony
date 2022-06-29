#!/bin/bash

source ./iac.bicep.sh
azlogin "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" 'AzureCloud'

pushd .

cd "${GITHUB_WORKSPACE}/IAC/Bicep/bicep"

SAVEIFS=$IFS
IFS=$'\n'
modules=($(find . -type f -name 'main.bicep' | sort -u))
IFS=$SAVEIFS

for deployment in "${modules[@]}"; do
    _information "Executing Bicep deploy: ${deployment}"

    path=$(dirname "${deployment}")

    params=()
    SAVEIFS=$IFS
    IFS=$'\n'
    params=($(find "${GITHUB_WORKSPACE}/env/bicep/${ENVIRONMENT}" -maxdepth 1 -type f -name '*parameters*.json'))
    param_tmp_deployment="${GITHUB_WORKSPACE}/env/bicep/${ENVIRONMENT}/${path//.\//}/"
    if [[ -d "${param_tmp_deployment}" ]]; then
        params+=($(find "${param_tmp_deployment}" -maxdepth 1 -type f -name '*parameters*.json' -and -not -name '*mockup*'))
    fi
    IFS=$SAVEIFS

    params_path=()
    for param_path_tmp in "${params[@]}"; do
        if [[ -f "${param_path_tmp}" ]]; then
            parse_bicep_parameters "${param_path_tmp}"
            params_path+=("${param_path_tmp}")
        fi
    done


    load_dotenv

    output=$(deploy "${deployment}" params_path "${GITHUB_RUN_ID}" "${LOCATION}" "${resourceGroupName}")
    exit_code=$?

    if [[ $exit_code != 0 ]]; then
        _error "Bicep deploy failed - returned code ${exit_code}"
        exit $exit_code
    fi

    bicep_output_to_env "${output}"

    echo "------------------------"
done

popd
