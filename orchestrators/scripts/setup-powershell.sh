#!/bin/bash

# Syntax: ./setup-powershell.sh [version]

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"latest"}"

# Get OS architecture
get_os_architecture "x64" "arm64" "arm32"

# Install the downloaded package
sudo dpkg -i powershell-lts_7.2.3-1.deb_amd64.deb

# Resolve missing dependencies and finish the install (if necessary)
sudo apt-get install -f
