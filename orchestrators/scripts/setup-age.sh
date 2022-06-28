#!/bin/bash

# Syntax: ./setup-age.sh [version]

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"latest"}"

# Get OS architecture
get_os_architecture

# Verify requested version is available, convert latest
find_version_from_git_tags VERSION 'https://github.com/FiloSottile/age'

_information "Downloading Age..."
filename="age-v${VERSION}-linux-${os_architecture}.tar.gz"
curl -sSL -o "${filename}" "https://github.com/FiloSottile/age/releases/download/v${VERSION}/${filename}"
tar -xf "${filename}" age
rm -f "${filename}"
sudo mv -f age/age /usr/local/bin/
sudo mv -f age/age-keygen /usr/local/bin/
rm -rf age
