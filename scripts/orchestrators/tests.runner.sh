#!/bin/bash

# include helpers
source _helpers.sh

usage() {
  cat <<EOF

Usage: ${0} [terraform or bicep]

  terraform         : run \`all\` terraform tests
    [optional] provide the name of the test file to run, e.g. source ${0} && terraform 00_dummy_test.go

  bicep             : run \`all\` bicep tests
    bicep arm_ttk   : run \`arm_ttk\`   bicep tests
    bicep pester    : run \`pester\`    bicep tests
      [optional] provide the name of the test file to run, e.g. source ${0} && bicep pester SqlIntegration.Tests.ps1
    bicep shellspec : run \`shellspec\` bicep tests

EOF
}

# @description: run tests for terraform
# @param ${1}: test file name
# @param ${2}: is a tag
# @usage <to run all the tests>: source ${0} && terraform
# @usage <to run {FILENAME} tests only>; source ${0} && terraform 00_dummy_test.go
terraform() {
  TEST_FILE_NAME=${1:-}
  IS_TAG=${2:-}

  # cd into the terraform directory
  pushd ../../terraform/

  # cleanup any existing state
  rm -rf ./terraform/**/.terraform
  rm -rf ./terraform/**/*.tfplan
  rm -rf ./terraform/**/*.tfstate
  rm -rf ./terraform/backend.tfvars
  rm -rf ./terraform/**/terraform.tfstate.backup

  # cd to the test directory
  cd ../test/terraform

  CWD=$(pwd)

  if [[ -z "${TEST_FILE_NAME}" && -z "${IS_TAG}" ]]; then
    # find all tests
    TEST_FILE_NAMES=$(find ${CWD}/*.go)

    # run all tests
    for TEST_FILE_NAME in ${TEST_FILE_NAMES}; do
      echo -e "--------------------------------------------------------------------------------\n[$(date)] : Running tests for '${TEST_FILE_NAME}'" | tee -a test.out

      go test -v -timeout 6000s ${TEST_FILE_NAME} | tee -a test.out
    done
  elif [ ! -z "${TEST_FILE_NAME}" ] && [ -z "${IS_TAG}" ]; then
    echo -e "--------------------------------------------------------------------------------\n[$(date)] : Running tests for '${TEST_FILE_NAME}'" | tee -a test.out

    # run a specific test
    echo "go test -v ${TEST_FILE_NAME}  2>&1 | go-junit-report > ${TEST_FILE_NAME/'.go'/'.xml'}"
    go test -v -timeout 8000s ${TEST_FILE_NAME} 2>&1 | go-junit-report >${TEST_FILE_NAME/'.go'/'.xml'}

    #gotestsum  --junitfile unit-tests.xml -- -tags=moule_test .\...
  else

    echo -e "--------------------------------------------------------------------------------\n[$(date)] : Running tests for tag '${TEST_FILE_NAME}'" | tee -a test.out

    # run tests of certain tag
    echo "go test -v -timeout 1000s --tags=${TEST_FILE_NAME}  2>&1 | go-junit-report > ${TEST_FILE_NAME}.xml"
    go test -v -timeout 1000s --tags=${TEST_FILE_NAME} 2>&1 | go-junit-report >"${TEST_FILE_NAME}.xml"

  fi

  popd
}

# @description: run tests for bicep
# @param ${1}: test type, options; arm-ttk, pester, shellspec
# @param ${2}: test file name
# @usage <to run all the tests>: source ${0} && bicep
# @usage <to run all the tests for arm-ttk>: source ${0} && bicep arm-ttk
# @usage <to run all the tests for pester>: source ${0} && bicep pester
# @usage <to run {FILENAME} tests only for pester>; source ${0} && bicep pester SqlIntegration.Tests.ps1
# @usage <to run all the tests for shellspec>: source ${0} && bicep shellspec
bicep() {
  source ./iac.bicep.sh

  # Set environment variables for BenchPress login
  export AZ_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID}"
  export AZ_TENANT_ID="${ARM_TENANT_ID}"
  export AZ_APPLICATION_ID="${ARM_CLIENT_ID}"
  export AZ_ENCRYPTED_PASSWORD=$(pwsh -Command "\"${ARM_CLIENT_SECRET}\" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString")

  pester() {
    _information "run end to end tests"

    pushd ./end_to_end
    # if the test file is not specified, run for all files
    if [ -z "${1}" ]; then
      pwsh -Command "Invoke-Pester -OutputFile test.xml -OutputFormat NUnitXML -EnableExit"
    else
      TEST_FILE=$(find ${1})

      if [ ! -z "${TEST_FILE}" ]; then
        pwsh -Command "Invoke-Pester -OutputFile test.xml -OutputFormat NUnitXML ${TEST_FILE} -EnableExit"
      fi
    fi

    # return to the previous directory
    popd
  }

  shellspec() {
    _information "run shellspec tests"
    pushd ./spec

    shellspec -f d

    # return to the previous directory
    popd
  }

  # cd to the tests directory
  pushd ../../IAC/Bicep/test

  if [ -z "${1}" ]; then
    pester "$@"
    shellspec "$@"
  elif [ "${1}" == "pester" ]; then
    pester ${2}
  elif [ "${1}" == "shellspec" ]; then
    shellspec ${2}
  fi

  popd
}
