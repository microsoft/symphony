#!/bin/bash

source ./iac.bicep.sh
azlogin "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" 'AzureCloud'

pushd .

cd "${WORKSPACE_PATH}/IAC/Bicep/bicep" || exit

SAVEIFS=${IFS}
IFS=$'\n'
modules=($(find . -type f -name 'main.bicep' | sort -u -r))
IFS=${SAVEIFS}

for deployment in "${modules[@]}"; do
  _information "Executing Bicep destroy: ${deployment}"

  layerName=$(basename "$(dirname "$(dirname "${deployment}")")")

  output=$(destroy "${ENVIRONMENT_NAME}" "${layerName}" "${LOCATION_NAME}")

  exit_code=$?

  if [[ ${exit_code} != 0 ]]; then
    _error "Bicep destroy failed - returned code ${exit_code}"
    exit ${exit_code}
  fi

  echo "------------------------"
done

popd || exit
