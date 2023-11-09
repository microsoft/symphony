#!/bin/bash

# Includes
source ./_helpers.sh

usage() {
  _information "Usage: scanners.sh -place holder for all scanners/security tools execution"
  exit 1
}

run_gitleaks() {
  local source_path=$1
  local report_format=$2
  local log_level=$3
  local redact=$4
  local verbose=$5
  local no_git=$6

  _information "Run Gitleaks detect cmd"

  cmd_options="--config ${source_path}/.gitleaks.toml --source ${source_path} --report-path ./gitleaks-report.${report_format} --report-format ${report_format} --log-level ${log_level}"

  if [[ ! -z "${redact}" ]]; then
    cmd_options+=" --redact"
  fi

  if [[ ! -z "${verbose}" ]]; then
    cmd_options+=" --verbose"
  fi

  if [[ ! -z "${no_git}" ]]; then
    cmd_options+=" --no-git"
  fi

  echo "gitleaks detect ${cmd_options}"
  gitleaks detect ${cmd_options}
  exit $?
}
# export -f run_gitleaks

run_armttk() {
  local bicep_file_path=$1

  az bicep build --file "${bicep_file_path}"
  arm-ttk/arm-ttk/Test-AzTemplate.sh "${bicep_file_path/.bicep/.json}"
}
# export -f run_armttk
