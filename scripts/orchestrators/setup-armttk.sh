#!/bin/bash

# Syntax: ./setup-armttk.sh [version]

# check if armttk is already installed
if [ -f "./arm-ttk/Test-AzTemplate.cmd" ]; then
  echo "armttk is already installed"
  exit 0
fi

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"20230619"}"

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

ARMTTK_PATH="$(dirname $(${LOCAL_READLINK} -f $0))/arm-ttk/arm-ttk"

pwsh -noprofile -nologo -command "Import-Module '${ARMTTK_PATH}/arm-ttk.psd1'"

chmod +x "${ARMTTK_PATH}/Test-AzTemplate.sh"

echo "PATH=${PATH:+${PATH}:}${ARMTTK_PATH}" >>~/.bashrc
