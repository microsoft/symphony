#!/bin/bash

# Syntax: ./setup-azcli.sh

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
