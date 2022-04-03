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

terraform() {
  TEST_FILE_NAME=${1:-}

  # cd into the terraform directory
  cd ../../IAC/Terraform/

  # cleanup any existing state
  rm -rf ./terraform/**/.terraform
  rm -rf ./terraform/**/*.tfplan
  rm -rf ./terraform/**/*.tfstate
  rm -rf ./terraform/backend.tfvars
  rm -rf ./terraform/**/terraform.tfstate.backup

  # cd to the test directory
  cd ./test

  CWD=$(pwd)

}
