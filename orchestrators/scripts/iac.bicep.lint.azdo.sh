#!/bin/bash

source ./iac.bicep.sh

pushd .

cd "${WORKSPACE_PATH}/IAC/Bicep/bicep"

SAVEIFS=$IFS
IFS=$'\n'
modules=($(find . -type f -name '*.bicep' | sort -u))
IFS=$SAVEIFS

for deployment in "${modules[@]}"; do
    _information "Executing Bicep lint: ${deployment}"

    lint "${deployment}"
    exit_code=$?

    if [[ $exit_code != 0 ]]; then
        _error "Bicep lint failed - returned code ${exit_code}"
        exit $exit_code
    fi

    echo "------------------------"
done

popd
