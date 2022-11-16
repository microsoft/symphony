#!/usr/bin/env bash

source scripts/utilities/shell_logger.sh
source scripts/install/banner.sh
source scripts/install/contents.sh

_information "Symphony Install"

declare ORCHESTRATOR=$1
declare IACTOOL=$2

#Bind command line arguments

main() {
    if [ $ORCHESTRATOR == "azdo" ]; then
      source scripts/install/providers/azdo/azdo.sh
      mkdir scripts/install/providers/azdo/temp
    else
      source scripts/install/providers/github.sh
    fi

    # workflow
    load_inputs
    configure_repo
    configure_credentials
    
    if [ $IACTOOL == "bicep" ]; then
      create_pipelines_bicep
      remove_tf_content
    else
      create_pipelines_terraform
      remove_bicep_content
    fi

    # push the code the repo
    push_repo_code
}

# Entry point
main