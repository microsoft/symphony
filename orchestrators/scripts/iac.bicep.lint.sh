#!/bin/bash

source ./iac.bicep.sh
source ./scanners.sh

pushd .

looking_path="${WORKSPACE_PATH}/IAC/Bicep/bicep"

cd "${looking_path}"

SAVEIFS=$IFS
IFS=$'\n'
modules=($(find . -type f -name '*.bicep' | sort -u))
IFS=$SAVEIFS

popd

# LINT
for deployment in "${modules[@]}"; do
    deployment=${deployment/'./'/"${looking_path}/"}

    _information "Executing Bicep lint for: ${deployment}"

    lint "${deployment}"
    exit_code=$?

    if [[ $exit_code != 0 ]]; then
        _error "Bicep lint failed - returned code ${exit_code}"
        exit $exit_code
    fi

    echo "------------------------"
done

# ARM-TTK
for deployment in "${modules[@]}"; do
    deployment=${deployment/'./'/"${looking_path}/"}
    _information "Executing ARM-TTK for: ${deployment}"

    run_armttk "${deployment}"
    exit_code=$?

    if [[ $exit_code != 0 ]]; then
        _error "ARM-TTK failed - returned code ${exit_code}"
        exit $exit_code
    fi

    echo "------------------------"
done
