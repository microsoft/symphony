#!/bin/bash

# Syntax: ./setup-azcli.sh

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e

_information "Installing Azure CLI..."

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
