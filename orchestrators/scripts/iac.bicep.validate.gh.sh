#!/bin/bash

source "${GITHUB_WORKSPACE}/orchestrators/scripts/iac.bicep.sh"
azlogin "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" 'AzureCloud'

pushd .

cd "${GITHUB_WORKSPACE}/IAC/Bicep/bicep"

SAVEIFS=$IFS
IFS=$'\n'
modules=($(find . -type f -name 'main.bicep' | sort -u))
IFS=$SAVEIFS

for deployment in "${modules[@]}"; do

    _information "bicep validate: ${deployment}"
    # pushd .
    path=$(dirname "${deployment}")
    # fileName=$(basename "${deployment}")

    # cd "${path}"

    params=()
    SAVEIFS=$IFS
    IFS=$'\n'
    params=($(find "${GITHUB_WORKSPACE}/env/bicep/${ENVIRONMENT}" -maxdepth 1 -type f -name '*parameters*.json'))
    param_tmp_deployment="${GITHUB_WORKSPACE}/env/bicep/${ENVIRONMENT}/${path//.\//}/"
    if [[ -d "${param_tmp_deployment}" ]]; then
        params+=($(find "${param_tmp_deployment}" -maxdepth 1 -type f -name '*parameters*.json'))
    fi
    IFS=$SAVEIFS

    params_path=()
    for param_path_tmp in "${params[@]}"; do
        if [[ -f "${param_path_tmp}" ]]; then
            parse_bicep_parameters "${param_path_tmp}"
            params_path+=("${param_path_tmp}")
        fi
    done

    validate "${deployment}" params_path "${GITHUB_RUN_ID}" "${LOCATION}" "rg-validate"
    code=$?
    if [[ $code != 0 ]]; then
        echo "bicep lint failed - returned code ${code}"
        exit $code
    fi
    # popd
    echo "------------------------"
done

popd
