#!/bin/bash

# Syntax: ./setup-sops.sh [version]

# check if sops is already installed
if [ -f "/usr/local/bin/sops" ]; then
  echo "sops is already installed"
  exit 0
fi

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"latest"}"

# Get OS architecture
get_os_architecture "amd64" "arm64"

# Verify requested version is available, convert latest
find_version_from_git_tags VERSION 'https://github.com/mozilla/sops'

_information "Downloading SOPS..."

filename="sops-v${VERSION}.linux.${os_architecture}"
echo "${filename}"
curl -sSL -o "${filename}" "https://github.com/mozilla/sops/releases/download/v${VERSION}/${filename}"
mv -f "${filename}" /usr/local/bin/sops
