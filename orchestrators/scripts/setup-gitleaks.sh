#!/bin/bash

# Syntax: ./setup-gitleaks.sh [gitleaks version]

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
GITLEAKS_VERSION="${1:-"latest"}"

# Get OS architecture
get_os_architecture "x64" "arm64" "armv7" "x32"

# Verify requested version is available, convert latest
find_version_from_git_tags GITLEAKS_VERSION 'https://github.com/zricethezav/gitleaks'

_information "Downloading Gitleaks..."
gitleaks_filename="gitleaks_${GITLEAKS_VERSION}_linux_${os_architecture}.tar.gz"
curl -sSL -o ${gitleaks_filename} "https://github.com/zricethezav/gitleaks/releases/download/v${GITLEAKS_VERSION}/${gitleaks_filename}"
tar -xf ${gitleaks_filename} gitleaks
rm -f ${gitleaks_filename}
mv -f gitleaks /usr/local/bin/
