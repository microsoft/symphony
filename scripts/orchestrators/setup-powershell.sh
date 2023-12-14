#!/bin/bash

# Syntax: ./setup-powershell.sh [version]

# check if powershell is already installed
if command -v pwsh &>/dev/null; then
  echo "PowerShell is already installed"
  exit 0
fi

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"latest"}"

# Get OS architecture
get_os_architecture "x64" "arm64" "arm32"

# Verify requested version is available, convert latest
find_version_from_git_tags VERSION 'https://github.com/PowerShell/PowerShell'

_information "Downloading PowerShell..."

filename="powershell-${VERSION}-linux-${os_architecture}.tar.gz"
target_path="$(pwd)/powershell/$(echo ${VERSION} | grep -oE '[^\.]+' | head -n 1)"
mkdir -p tmp/pwsh "${target_path}"
cd tmp/pwsh
curl -sSL -o "${filename}" "https://github.com/PowerShell/PowerShell/releases/download/v${VERSION}/${filename}"
tar -xf "${filename}" -C "${target_path}"
ln -s "${target_path}/pwsh" /usr/local/bin/pwsh
rm -rf tmp/pwsh
