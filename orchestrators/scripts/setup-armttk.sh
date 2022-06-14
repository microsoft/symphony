#!/bin/bash

# Syntax: ./setup-armttk.sh [version]

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"latest"}"

# Verify requested version is available, convert latest
find_version_from_git_tags VERSION 'https://github.com/Azure/arm-ttk' 'tags/' 'none'

_information "Downloading ARM-TTK..."
filename="arm-ttk.zip"
curl -sSL -o "${filename}" "https://github.com/Azure/arm-ttk/releases/download/${VERSION}/${filename}"
unzip "${filename}"
rm -f "${filename}"

pwsh -Command ./Setup-ARMTTK.ps1
