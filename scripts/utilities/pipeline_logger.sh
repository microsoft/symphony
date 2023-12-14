#!/usr/bin/env bash

# Logger Functions with colors for Bash Shell

_debug() {
  # Only print debug lines if debugging is turned on.
  if [ -n "${DEBUG_FLAG}" ]; then
    if [ -n "${GITHUB_ACTION}" ]; then
      echo "::debug::" "$@"
    elif [ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}" ]; then
      echo -e "##[debug]" "$@"
    else
      echo "DEBUG: " "$@"
    fi
  fi
}

_error() {
  if [ -n "${GITHUB_ACTION}" ]; then
    echo "::error::" "$@"
  elif [ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}" ]; then
    echo -e "##[error]" "$@"
  else
    echo "ERROR: " "$@"
  fi
}

_warning() {
  if [ -n "${GITHUB_ACTION}" ]; then
    echo "::warning::" "$@"
  elif [ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}" ]; then
    echo -e "##[warning]" "$@"
  else
    echo "WARNING: " "$@"
  fi
}

_information() {
  if [ -n "${GITHUB_ACTION}" ]; then
    echo "::notice::" "$@"
  elif [ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}" ]; then
    echo -e "##[command]" "$@"
  else
    echo "NOTICE: " "$@"
  fi
}

_success() {
  if [ -n "${GITHUB_ACTION}" ]; then
    echo "::notice::" "$@"
  elif [ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}" ]; then
    echo -e "##[section]" "$@"
  else
    echo "NOTICE: " "$@"
  fi
}
