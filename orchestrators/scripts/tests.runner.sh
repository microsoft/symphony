#!/bin/bash

# include helpers
source _helpers.sh

usage() {
  _information "Usage: ${0} [terraform or bicep]"
  exit 1
}

print() {
  _success "${1}"

  echo -e "--------------------------------------------------------------------------------\n[$(date)] : ${1}" | tee -a test.out
}

