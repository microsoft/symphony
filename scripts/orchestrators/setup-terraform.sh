#!/bin/bash

# Syntax: ./setup-terraform.sh [version]

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"latest"}"

# Get OS architecture
get_os_architecture

# Verify requested version is available, convert latest
find_version_from_git_tags VERSION 'https://github.com/hashicorp/terraform'

_information "Downloading Terraform..."

filename="terraform_${VERSION}_linux_${os_architecture}.zip"
curl -sSL -o "${filename}" "https://releases.hashicorp.com/terraform/${VERSION}/${filename}"
unzip "${filename}"
rm -f "${filename}"
# ln -s "terraform" /usr/local/bin/terraform
mv -f terraform /usr/local/bin/
