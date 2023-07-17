#!/bin/bash

# Syntax: ./setup-benchpress.sh

# check if Az Module is already installed
AZ_MODULE_PATH=$(pwsh -c "Get-Module -ListAvailable -Name Az | Select-Object -ExpandProperty Path")
if [ -n "${AZ_MODULE_PATH}" ]; then
  echo "Az Module is already installed"
else
  echo "Installing Az Module"

  pwsh -noprofile -nologo -command 'Install-Module -Name Az -AllowClobber -Force -Confirm:$False -SkipPublisherCheck'
fi

# check if Az.App Module is already installed
AZ_APP_MODULE_PATH=$(pwsh -c "Get-Module -ListAvailable -Name Az.App | Select-Object -ExpandProperty Path")
if [ -n "${AZ_APP_MODULE_PATH}" ]; then
  echo "Az.App Module is already installed"
else
  echo "Installing Az.App Module"

  pwsh -noprofile -nologo -command 'Install-Module -Name Az.App -AllowClobber -Force -Confirm:$False -SkipPublisherCheck'
fi

# check if Az.Portal Module is already installed
AZ_PORTAL_MODULE_PATH=$(pwsh -c "Get-Module -ListAvailable -Name Az.Portal | Select-Object -ExpandProperty Path")
if [ -n "${AZ_PORTAL_MODULE_PATH}" ]; then
  echo "Az.Portal Module is already installed"
else
  echo "Installing Az.Portal Module"

  pwsh -noprofile -nologo -command 'Install-Module -Name Az.Portal -AllowClobber -Force -Confirm:$False -SkipPublisherCheck'
fi

# check if BenchPress.Azure Module is already installed
BENCHPRESS_AZURE_MODULE_PATH=$(pwsh -c "Get-Module -ListAvailable -Name BenchPress.Azure | Select-Object -ExpandProperty Path")
if [ -n "${BENCHPRESS_AZURE_MODULE_PATH}" ]; then
  echo "BenchPress.Azure Module is already installed"
else
  echo "Installing BenchPress.Azure Module"

  pwsh -noprofile -nologo -command 'Install-Module -Name BenchPress.Azure -AllowClobber -Force -Confirm:$False -SkipPublisherCheck'
fi
