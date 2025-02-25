#!/bin/bash

# Syntax: ./setup-azcli.sh

# If it's running as a Github action, Create a temporary directory
# for Azure CLI configuration isolation

if [ "$GITHUB_ACTIONS" == "true" ]; then
  temp_dir=$(mktemp -d)
  export AZURE_CONFIG_DIR="$temp_dir"
  echo "AZURE_CONFIG_DIR=$AZURE_CONFIG_DIR" >> $GITHUB_ENV
fi

# check if azurecli is already installed
if command -v az &>/dev/null; then
  echo "Azure CLI is already installed"
  exit 0
fi

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e

_information "Installing Azure CLI..."

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
