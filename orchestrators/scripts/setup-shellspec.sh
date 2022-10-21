#!/bin/bash

# Syntax: ./setup-shellspec.sh [version]

# check if shellspec is already installed
if [ -f "./shellspec/shellspec" ]; then
  echo "Shellspec is already installed"
  exit 0
fi

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"latest"}"

# Verify requested version is available, convert latest
find_version_from_git_tags VERSION 'https://github.com/shellspec/shellspec' 'tags/'

_information "Downloading ShellSpec..."
filename="shellspec-dist.tar.gz"
curl -sSL -o "${filename}" "https://github.com/shellspec/shellspec/releases/download/${VERSION}/${filename}"
tar -xzf "${filename}"
rm -f "${filename}"
ln -s "shellspec/shellspec" /usr/local/bin/shellspec
