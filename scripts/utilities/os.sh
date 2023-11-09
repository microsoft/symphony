#!/usr/bin/env bash

get_current_os() {
  echo "$OSTYPE"
}

check_linux_os() {
  if [[ $OSTYPE == *"linux"* ]]; then
    return 0
  fi
  return 1
}

check_mac_os() {
  if [[ $OSTYPE == *"darwin"* ]]; then
    return 0
  fi
  return 1
}
