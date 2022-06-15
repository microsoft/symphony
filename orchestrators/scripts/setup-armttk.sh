#!/bin/bash

# Syntax: ./setup-armttk.sh [version]

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"latest"}"

# Verify requested version is available, convert latest
find_version_from_git_tags VERSION 'https://github.com/Azure/arm-ttk' 'tags/' 'none'

_information "Downloading ARM-TTK..."
filename="arm-ttk.zip"
curl -sSL -o "${filename}" "https://github.com/Azure/arm-ttk/releases/download/${VERSION}/${filename}"
unzip "${filename}"
rm -f "${filename}"

LOCAL_READLINK=readlink

# https://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux
unameOut="$(uname -s)"
case "${unameOut}" in
    Darwin*) LOCAL_READLINK=greadlink ;;
esac

pwsh -noprofile -nologo -command "Import-Module '$(dirname $(${LOCAL_READLINK} -f $0))/arm-ttk.psd1'"
