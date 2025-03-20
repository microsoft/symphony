#!/bin/bash

# Syntax: ./setup-powershell.sh [version]

# check if powershell is already installed

if which pwsh &>/dev/null; then
  echo "PowerShell is already installed"
  exit 0
fi

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e

_information "Installing PowerShell..."

sudo apt install -y wget apt-transport-https software-properties-common
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update

sudo apt install -y powershell
