#!/bin/bash

get_os_architecture() {
  local arch_amd64="${1:-"amd64"}"
  local arch_arm64="${2:-"arm64"}"
  local arch_arm="${3:-"arm"}"
  local arch_386="${4:-"386"}"

  os_architecture="$(uname -m)"
  case ${os_architecture} in
  x86_64) os_architecture="${arch_amd64}" ;;
  aarch64 | armv8*) os_architecture="${arch_arm64}" ;;
  aarch32 | armv7* | armvhf*) os_architecture="${arch_arm}" ;;
  i?86) os_architecture="${arch_386}" ;;
  *)
    _error "Architecture ${os_architecture} unsupported"
    exit 1
    ;;
  esac
}

# Figure out correct version of a three part version number is not passed
find_version_from_git_tags() {
  local variable_name=$1
  local requested_version=${!variable_name}
  if [ "${requested_version}" = "none" ]; then return; fi
  local repository=$2
  local prefix=${3:-"tags/v"}
  local separator=${4:-"."}
  local last_part_optional=${5:-"false"}

  if [ "${separator}" = "none" ]; then
    separator=""
  fi

  if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
    local escaped_separator=${separator//./\\.}
    local last_part
    if [ "${last_part_optional}" = "true" ]; then
      last_part="(${escaped_separator}[0-9]+)?"
    else
      last_part="${escaped_separator}[0-9]+"
    fi
    local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
    local version_list="$(git ls-remote --tags "${repository}" | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
    if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
      declare -g "${variable_name}"="$(echo "${version_list}" | head -n 1)"
    else
      set +e
      declare -g "${variable_name}"="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
      set -e
    fi
  fi
  if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" >/dev/null 2>&1; then
    _error "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
    exit 1
  fi
  echo "${variable_name}=${!variable_name}"
}
