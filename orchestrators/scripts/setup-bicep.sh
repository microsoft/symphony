#!/bin/bash

# Syntax: ./setup-bicep.sh [version]

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"latest"}"

# Get OS architecture
get_os_architecture "x64"

# Verify requested version is available, convert latest
find_version_from_git_tags VERSION 'https://github.com/Azure/bicep'

_information "Downloading Bicep..."
filename="bicep"
curl -sSL -o "${filename}" "https://github.com/Azure/bicep/releases/download/v${VERSION}/bicep-linux-${os_architecture}"
chmod +x "./${filename}"
sudo mv "./${filename}" "/usr/local/bin/${filename}"
