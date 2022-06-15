#!/bin/bash

# Syntax: ./setup-pester.sh

# Includes
source _helpers.sh
source _setup_helpers.sh

_information "Downloading Perster..."

pwsh -noprofile -nologo -command "Install-Module -Name Pester -AllowClobber -Force -Confirm:$False -SkipPublisherCheck; Import-Module Pester"
