#!/bin/bash
INSTALL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$INSTALL_DIR"/../utilities/shell_logger.sh

# TARGET_ROOT should be fined in the calling script that sources this utilities file.

function remove_yaml() {
  if [ "$ORCHESTRATOR" == "azdo" ]; then
    rm -r "$TARGET_ROOT"/.github/*
  else
    rm -r "$TARGET_ROOT"/.azure-pipelines/*
    rm "$TARGET_ROOT"/.github/CODEOWNERS
  fi
}
function remove_tf_content() {
  _information "Remove Terraform IaC modules"
  rm -r "$TARGET_ROOT"/IAC/Terraform/*
  rm -r "$TARGET_ROOT"/IAC/Terraform

  _information "Remove Terraform env"
  rm -r "$TARGET_ROOT"/env/terraform/*
  rm -r "$TARGET_ROOT"/env/terraform

  if [ "$ORCHESTRATOR" == "azdo" ]; then
    _information "Remove Terraform Azdo pipeline"
    rm "$TARGET_ROOT"/.azure-pipelines/*.terraform*.yml
  else
    _information "Remove Terraform GitHub workflows"
    rm "$TARGET_ROOT"/.github/workflows/*.terraform*.yml
  fi

  _information "Remove Terraform orchestrators scripts"
  rm "$TARGET_ROOT"/scripts/orchestrators/*.tf.*.sh
  rm "$TARGET_ROOT"/scripts/orchestrators/*terraform*.sh
  rm "$TARGET_ROOT"/scripts/orchestrators/*tflint.sh
}

function remove_bicep_content() {

  _information "Remove Bicep IaC modules"
  rm -r "$TARGET_ROOT"/IAC/Bicep/*
  rm -r "$TARGET_ROOT"/IAC/Bicep

  _information "Remove Bicep env"
  rm -r "$TARGET_ROOT"/env/bicep/*
  rm -r "$TARGET_ROOT"/env/bicep

  if [ "$ORCHESTRATOR" == "azdo" ]; then
    _information "Remove Bicep Azdo pipeline"
    rm "$TARGET_ROOT"/.azure-pipelines/*.bicep*.yml
  else
    _information "Remove Bicep GitHub workflows"
    rm "$TARGET_ROOT"/.github/workflows/*.bicep*.yml
  fi

  _information "Remove Bicep orchestrators scripts"
  rm "$TARGET_ROOT"/scripts/orchestrators/*bicep*.sh
  rm "$TARGET_ROOT"/scripts/orchestrators/*powershell*.sh
  rm "$TARGET_ROOT"/scripts/orchestrators/*shellspec*.sh
  rm "$TARGET_ROOT"/scripts/orchestrators/*pester.sh
  rm "$TARGET_ROOT"/scripts/orchestrators/setup-armttk.sh
}

function remove_tmp_terraform() {
  _information "Remove temporary Terraform files"
  rm -r "$TARGET_ROOT"/IAC/Terraform/test/terraform/mocked_deployment.tfstate
}
