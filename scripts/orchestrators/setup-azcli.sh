#!/bin/bash

# Syntax: ./setup-azcli.sh

# Create a temporary directory for Azure CLI configuration isolation
temp_dir=$(mktemp -d)
export AZURE_CONFIG_DIR="$temp_dir"
echo "AZURE_CONFIG_DIR=$AZURE_CONFIG_DIR" >> $GITHUB_ENV

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
