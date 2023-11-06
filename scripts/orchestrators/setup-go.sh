#!/bin/bash

# Syntax: ./setup-go.sh [version]

# check if go is already installed
if command -v go &>/dev/null; then
  echo "Go is already installed"
  exit 0
fi

# Includes
source _helpers.sh
source _setup_helpers.sh

set -e
VERSION="${1:-"latest"}"
GOROOT=${2:-"usr/local/go"}
GOPATH=${3:-"$HOME/go"} #"go"}
USERNAME=${4:-$(whoami)}
INSTALL_GO_TOOLS=${5:-"true"}

updaterc() {
  if [ "${UPDATE_RC}" = "true" ]; then
    echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
    if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
      echo -e "$1" >>/etc/bash.bashrc
    fi
    if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
      echo -e "$1" >>/etc/zsh/zshrc
    fi
  fi
}

# Get OS architecture
get_os_architecture "amd64" "arm64" "armv6l" "386"

# Verify requested version is available, convert latest
find_version_from_git_tags VERSION "https://go.googlesource.com/go" "tags/go" "." "true"

_information "Downloading Go..."

# Install Go
umask 0002
# if ! cat /etc/group | grep -e "^golang:" >/dev/null 2>&1; then
#     groupadd -r golang
# fi
# usermod -a -G golang "${USERNAME}"
mkdir -p "${GOROOT}" "${GOPATH}"
if [ "${VERSION}" != "none" ] && ! type go >/dev/null 2>&1; then
  _information "Downloading Go ${VERSION}..."
  set +e

  curl -fsSL -o tmp/go.tar.gz "https://golang.org/dl/go${VERSION}.linux-${os_architecture}.tar.gz"
  exit_code=$?
  set -e
  if [ "${exit_code}" != "0" ]; then
    echo "(!) Download failed."
    # Try one break fix version number less if we get a failure
    major="$(echo "${VERSION}" | grep -oE '^[0-9]+' || echo '')"
    minor="$(echo "${VERSION}" | grep -oP '^[0-9]+\.\K[0-9]+' || echo '')"
    breakfix="$(echo "${VERSION}" | grep -oP '^[0-9]+\.[0-9]+\.\K[0-9]+' 2>/dev/null || echo '')"
    if [ "${breakfix}" = "" ] || [ "${breakfix}" = "0" ]; then
      ((minor = minor - 1))
      VERSION="${major}.${minor}"
      find_version_from_git_tags VERSION "https://go.googlesource.com/go" "tags/go" "." "true"
    else
      ((breakfix = breakfix - 1))
      VERSION="${major}.${minor}.${breakfix}"
    fi
    _information "Trying ${VERSION}..."
    curl -fsSL -o tmp/go.tar.gz "https://golang.org/dl/go${VERSION}.linux-${os_architecture}.tar.gz"
  fi
  _information "Extracting Go ${VERSION}..."
  tar -xzf tmp/go.tar.gz -C "${GOROOT}" --strip-components=1
  rm -rf tmp/go.tar.gz
else
  _warning "Go already installed. Skipping."
fi

# Install Go tools that are isImportant && !replacedByGopls based on
# https://github.com/golang/vscode-go/blob/v0.32.0/src/goToolsInformation.ts
GO_TOOLS="\
    golang.org/x/tools/gopls@latest \
    honnef.co/go/tools/cmd/staticcheck@latest \
    golang.org/x/lint/golint@latest \
    github.com/mgechev/revive@latest \
    github.com/uudashr/gopkgs/v2/cmd/gopkgs@latest \
    github.com/ramya-rao-a/go-outline@latest \
    github.com/go-delve/delve/cmd/dlv@latest \
    github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
if [ "${INSTALL_GO_TOOLS}" = "true" ]; then
  _information "Installing common Go tools..."
  export PATH=${GOROOT}/bin:${PATH}
  GOTOOLS_PATH="$(pwd)/tmp/gotools"
  _information " create bin directory"
  mkdir -p "${GOTOOLS_PATH}/bin"
  echo ${GOTOOLS_PATH}
  ls ${GOTOOLS_PATH}
  mkdir -p "${GOPATH}/bin"
  mkdir -p "${GOTOOLS_PATH}" ${GOPATH}/bin

  ls "${GOTOOLS_PATH}"
  _information "------ GOPATH------------"
  echo ${GOPATH}
  ls "${GOPATH}"

  _information "------ ------------"
  cd "${GOTOOLS_PATH}"
  # export GOPATH="${GOTOOLS_PATH}"
  # export GOCACHE="${GOTOOLS_PATH}/cache"

  # Use go get for versions of go under 1.16
  go_install_command=install
  if [[ "1.16.0" > "$(go version | grep -oP 'go\K[0-9]+\.[0-9]+(\.[0-9]+)?')" ]]; then
    export GO111MODULE=on
    go_install_command="get"
    _information "Go version < 1.16, using go get."
  fi

  (echo "${GO_TOOLS}" | xargs -n 1 go ${go_install_command} -v) 2>&1 | tee -a /tmp/go.log

  # Move Go tools into path and clean up

  _information "------ post tool installation ------------"
  _information "------ ls GOPATH/bin------------"
  echo "${GOPATH}"
  ls "${GOPATH}/bin"

  _information "------ ls GOTOOLS_PATH/bin------------"
  echo "${GOTOOLS_PATH}/bin"
  ls "${GOTOOLS_PATH}/bin"

  #mv ${GOTOOLS_PATH}/bin/* ${GOPATH}/bin

  #rm -rf "${GOTOOLS_PATH}"
fi

# Add GOPATH variable and bin directory into PATH in bashrc/zshrc files (unless disabled)
updaterc "$(
  cat <<EOF
export GOPATH="${GOPATH}"
if [[ "\${PATH}" != *"\${GOPATH}/bin"* ]]; then export PATH="\${PATH}:\${GOPATH}/bin"; fi
export GOROOT="${GOROOT}"
if [[ "\${PATH}" != *"\${GOROOT}/bin"* ]]; then export PATH="\${PATH}:\${GOROOT}/bin"; fi
EOF
)"

# chown -R :golang "${GOROOT}" "${GOPATH}"
chmod -R g+r+w "${GOROOT}" "${GOPATH}"
find "${GOROOT}" -type d | xargs -n 1 chmod g+s
find "${GOPATH}" -type d | xargs -n 1 chmod g+s

_information "Done!"
