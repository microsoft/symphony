#!/bin/bash

# Syntax: ./setup-terraform.sh [terraform version]

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
TERRAFORM_VERSION="${1:-"latest"}"

# Get OS architecture
get_os_architecture

# Verify requested version is available, convert latest
find_version_from_git_tags TERRAFORM_VERSION 'https://github.com/hashicorp/terraform'

_information "Downloading Terraform..."
terraform_filename="terraform_${TERRAFORM_VERSION}_linux_${os_architecture}.zip"
curl -sSL -o ${terraform_filename} "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${terraform_filename}"
unzip ${terraform_filename}
rm -f ${terraform_filename}
mv -f terraform /usr/local/bin/
