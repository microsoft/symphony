#!/bin/bash

# Syntax: ./setup-tflint.sh [version]

# check if tflint is already installed
if [ -f "/usr/local/bin/tflint" ]; then
  echo "tflint is already installed"
  exit 0
fi

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"latest"}"

# Get OS architecture
get_os_architecture

# Verify requested version is available, convert latest
find_version_from_git_tags VERSION 'https://github.com/terraform-linters/tflint'

_information "Downloading Tflint v${VERSION} ..."

filename="tflint_linux_${os_architecture}.zip"
curl -sSL -o "${filename}" "https://github.com/terraform-linters/tflint/releases/download/v${VERSION}/${filename}"
unzip "${filename}"
rm -f "${filename}"
mv -f tflint /usr/local/bin/
