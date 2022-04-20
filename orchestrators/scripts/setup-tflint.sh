#!/bin/bash

# Syntax: ./setup-tflint.sh [version]

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"latest"}"

# Get OS architecture
get_os_architecture

# Verify requested version is available, convert latest
find_version_from_git_tags VERSION 'https://github.com/terraform-linters/tflint'

_information "Downloading Tetflint..."
filename="tflint_linux_${os_architecture}.zip"
curl -sSL -o "${filename}" "htttps://github.com/terraform-linters/tflint/releases/download/${VERSION}/${filename}"
unzip "${filename}"
rm -f "${filename}"
mv -f tflint /usr/local/bin/