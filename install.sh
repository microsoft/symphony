#!/usr/bin/env bash

source scripts/utilities/shell_logger.sh
source scripts/utilities/shell_inputs.sh
source scripts/utilities/http.sh
source scripts/utilities/service_principal.sh
source scripts/install/banner.sh
source scripts/install/contents.sh

#script name
declare me=$(basename "$0")

declare ORCHESTRATOR=$1
declare IACTOOL=$2

main() {
  _information "This install script deprecated, please source setup.sh and use the symphony cli"

  source ./setup.sh
  symphony pipeline config "$ORCHESTRATOR" "$IACTOOL"
}

# Entry point
main
