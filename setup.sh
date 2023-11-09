#!/usr/bin/env bash
declare INSTALL_PATH=$(pwd)/scripts/install/cli
declare SCRIPTS_PATH=$(pwd)/scripts
source "$SCRIPTS_PATH/utilities/shell_logger.sh"

if [[ "$0" = "$BASH_SOURCE" ]]; then
    _error "WARNING: setup.sh should not executed directly. Please source this script."
    echo ""
    _information "source setup.sh"
    exit 1
fi

export PATH=$PATH:$INSTALL_PATH

echo ""
_success "Added Symphony temporarily ($INSTALL_PATH) to PATH"
echo ""
