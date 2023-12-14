#!/bin/bash

echo 'Run tflint'
source ./iac.tf.sh
pushd "${WORKSPACE_PATH}/IAC/Terraform/terraform"

SAVEIFS=${IFS}
IFS=$'\n'
modules=($(find . -type d | sort | awk '$0 !~ last "/" {print last} {last=$0} END {print last}'))
SAVEIFS=${IFS}

for deployment in "${modules[@]}"; do
  _information "Executing tf lint for: ${deployment}"
  pushd ${deployment}
  lint
  code=$?
  if [[ $code != 0 ]]; then
    _error "tflint failed- returned code ${code}"
    exit ${code}
  fi
  popd

done
popd
