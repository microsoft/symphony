#!/bin/bash

# Syntax: ./setup-pester.sh

# check if azure powershell is already installed
AZ_MODULE_PATH=$(pwsh -c "Get-Module -ListAvailable -Name Az | Select-Object -ExpandProperty Path")
if [ -n "${AZ_MODULE_PATH}" ]; then
  echo "Azure Powershell is already installed"
  exit 0
fi

# Includes
source _helpers.sh
source _setup_helpers.sh

_information "Downloading Azure Powershell Module..."

pwsh -noprofile -nologo -command 'Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force'
