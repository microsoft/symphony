#!/bin/bash
_error() {
    printf "\e[31mERROR: $@\n\e[0m"
}

_information() {
    printf "\e[36m$@\n\e[0m"
}

_success() {
    printf "\e[32m$@\n\e[0m"
}

usage() {
    _information "Usage: scanners.sh -place holder for all scanners/security tools execution"
    exit 1
}

run_gitleaks (){
    source_path=$1
    report_path=$2
    report_format=$3
    log_level=$4
    verbose=$5
    redact=$6
    no_git=$7

    _information "Run Gitleaks detect cmd"
   
    cmd_options=" --source ${source_path} --report-path ${report_path} --report-format ${report_format} --log-level ${log_level}"

    if [[  ! -z "$5" ]]; then
        cmd_options="${cmd_options} --verbose"
    fi

    if [[  ! -z "$6" ]]; then
        cmd_options="${cmd_options} --redact"
    fi

    if [[  ! -z "$7" ]]; then
        cmd_options="${cmd_options} --no-git"
    fi

    echo "gitleaks detect ${cmd_options}"
    gitleaks detect ${cmd_options}
    exit $?    
}
