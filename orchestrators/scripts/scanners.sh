#!/bin/bash

# Includes
source ./_helpers.sh

usage() {
    _information "Usage: scanners.sh -place holder for all scanners/security tools execution"
    exit 1
}

run_gitleaks() {
    source_path=$1
    report_path=$2
    report_format=$3
    log_level=$4
    verbose=$5
    redact=$6
    no_git=$7

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
export -f run_gitleaks

run_armttk() {
    echo 1
    # _information "Execute Bicep ARM-TTK"
    # TODO (enpolat): Test-AzTemplate.sh ${bicep_file_path}
}
export -f run_armttk
