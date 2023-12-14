#!/bin/bash

source ./iac.bicep.sh
source ./scanners.sh

pushd .

looking_path="${WORKSPACE_PATH}/IAC/Bicep/bicep"

cd "${looking_path}" || exit

SAVEIFS=${IFS}
IFS=$'\n'
modules=($(find . -type f -name '*.bicep' | sort -u))
IFS=${SAVEIFS}

popd || exit

# LINT
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

  deployment=${deployment/'./'/"${looking_path}/"}

  _information "Executing Bicep lint for: ${deployment}"

  lint "${deployment}"
  exit_code=$?

  if [[ ${exit_code} != 0 ]]; then
    _error "Bicep lint failed - returned code ${exit_code}"
    exit ${exit_code}
  fi

  _information "------------------------"
done

# ARM-TTK
for deployment in "${modules[@]}"; do
  deployment=${deployment/'./'/"${looking_path}/"}
  _information "Executing ARM-TTK for: ${deployment}"

  run_armttk "${deployment}"
  exit_code=$?

  if [[ ${exit_code} != 0 ]]; then
    _error "ARM-TTK failed - returned code ${exit_code}"
    exit ${exit_code}
  fi

  echo "------------------------"
done
