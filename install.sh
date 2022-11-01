#!/usr/bin/env bash

source scripts/utilities/shell_logger.sh
source scripts/install/banner.sh

_information "Symphony Install"

declare ORCHESTRATOR=$1

#Bind command line arguments

main() {
    if [ $ORCHESTRATOR == "azdo" ]; then
      source scripts/install/providers/azdo.sh
    else
      source scripts/install/providers/github.sh
    fi

    # workflow
    create_pipeline

}

# Entry point
main