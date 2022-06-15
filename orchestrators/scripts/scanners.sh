#!/bin/bash

# Includes
source ./_helpers.sh

usage() {
    _information "Usage: scanners.sh -place holder for all scanners/security tools execution"
    exit 1
}

run_gitleaks() {
    local source_path=$1
    local report_path=$2
    local report_format=$3
    local log_level=$4
    local verbose=$5
    local redact=$6
    local no_git=$7

    _information "Run Gitleaks detect cmd"

    cmd_options="--source ${source_path} --report-path ${report_path} --report-format ${report_format} --log-level ${log_level}"

    if [[ ! -z "$5" ]]; then
        cmd_options+=" --verbose"
    fi

    if [[ ! -z "$6" ]]; then
        cmd_options+=" --redact"
    fi

    if [[ ! -z "$7" ]]; then
        cmd_options+=" --no-git"
    fi

    echo "gitleaks detect ${cmd_options}"
    gitleaks detect ${cmd_options}
    exit $?
}
# export -f run_gitleaks

run_armttk() {
    # local root_dir=$1
    local bicep_file_path=$1

    az bicep build --file "${bicep_file_path}"
    # pushd .
    # cd "arm-ttk"
    Test-AzTemplate.sh "${bicep_file_path/.bicep/.json}"
    # popd
}
# export -f run_armttk
