#!/usr/bin/env bash

_error() {
  printf " \e[31mError: %s\n\e[0m" "$@"
}

_fail() {
  step=$1
  printf "\e[31mFailed $step\n\e[0m"
  printf "\e[31mError: $2\n\e[0m"
  printf "\e[31mResources may have been deployed. Please run symphony destroy to clean up orphaned resources.\n\e[0m"
  exit 1
}

_danger() {
  printf " \e[31m%s\n\e[0m" "$@"
}

_prompt() {
  printf "\n\e[35m>%s\n\e[0m" "$@"
}

_debug() {
  #Only print debug lines if debugging is turned on.
  if [ "$DEBUG_FLAG" == true ]; then
    msg="$@"
    LIGHT_CYAN='\033[0;35m'
    NC='\033[0m'
    printf "DEBUG: ${NC} %s ${NC}\n" "${msg}"
  fi
}

_information() {
  printf "\e[36m%s\n\e[0m" "$@"
}

_success() {
  printf "\e[32m%s\n\e[0m" "$@"
}

_debug_json() {
  if [ -n "$DEBUG_FLAG" ]; then
    echo "$@" | jq
  fi
}
