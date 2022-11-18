#!/usr/bin/env bash

source scripts/utilities/shell_logger.sh
source scripts/utilities/shell_inputs.sh
source scripts/utilities/service_principal.sh
source scripts/install/banner.sh
source scripts/install/contents.sh

#script name
declare me=`basename "$0"`

declare ORCHESTRATOR=$1
declare IACTOOL=$2

main() {
    show_banner
    _validate_inputs
    if [ $ORCHESTRATOR == "azdo" ]; then
      source scripts/install/providers/azdo/azdo.sh
      mkdir -p scripts/install/providers/azdo/temp
    else
      source scripts/install/providers/github.sh
    fi

    # workflow
    loadServicePrincipalCredentials
    printEnvironment
    load_inputs
    configure_repo
    configure_credentials
    
    # cleanup
    remove_yaml
    if [ $IACTOOL == "bicep" ]; then
      create_pipelines_bicep
      remove_tf_content
    else
      create_pipelines_terraform
      remove_bicep_content
    fi
    git add .
    git commit -m "cleanup unused iac files"
    
    # push the code the repo
    git push origin --all
}

# Entry point
main