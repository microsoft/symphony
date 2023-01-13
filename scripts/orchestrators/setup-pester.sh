#!/bin/bash

# Syntax: ./setup-pester.sh

# check if pester is already installed
PESTER_MODULE_PATH=$(pwsh -c "Get-Module -ListAvailable -Name Pester | Select-Object -ExpandProperty Path")
if [ -n "${PESTER_MODULE_PATH}" ]; then
  echo "Pester is already installed"
  exit 0
fi

# Includes
source _helpers.sh
source _setup_helpers.sh

_information "Downloading Pester..."

pwsh -noprofile -nologo -command 'Install-Module -Name Pester -AllowClobber -Force -Confirm:$False -SkipPublisherCheck; Import-Module Pester'
