#!/bin/bash

# Syntax: ./setup-pester.sh

# Includes
source _helpers.sh
source _setup_helpers.sh

_information "Downloading Perster..."

pwsh -Command ./Setup-Pester.ps1
