#!/bin/bash

# Syntax: ./setup-gitleaks.sh [version]

# check if gitleaks is already installed
if [ -f "/usr/local/bin/gitleaks" ]; then
  echo "gitleaks is already installed"
  exit 0
fi

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"latest"}"

# Get OS architecture
get_os_architecture "x64" "arm64" "armv7" "x32"

# Verify requested version is available, convert latest
find_version_from_git_tags VERSION 'https://github.com/gitleaks/gitleaks'

_information "Downloading Gitleaks..."

filename="gitleaks_${VERSION}_linux_${os_architecture}.tar.gz"
curl -sSL -o "${filename}" "https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/${filename}"
tar -xf "${filename}" gitleaks
rm -f "${filename}"
mv -f gitleaks /usr/local/bin/
