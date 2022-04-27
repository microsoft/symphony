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
# @usage <to run all the tests>: source ${0} && terraform
# @usage <to run {FILENAME} tests only>; source ${0} && terraform 00_dummy_test.go
terraform() {
  TEST_FILE_NAME=${1:-}

  # cd into the terraform directory
  pushd ../../IAC/Terraform/

  # cleanup any existing state
  rm -rf ./terraform/**/.terraform
  rm -rf ./terraform/**/*.tfplan
  rm -rf ./terraform/**/*.tfstate
  rm -rf ./terraform/backend.tfvars
  rm -rf ./terraform/**/terraform.tfstate.backup

  # cd to the test directory
  cd ./test

  # install go-junit-report
  go get -u github.com/jstemmer/go-junit-report

  CWD=$(pwd)

  if [ -z "${TEST_FILE_NAME}" ]; then
      # find all tests
      TEST_FILE_NAMES=`find ${CWD}/**/*.go`

      # run all tests
      for TEST_FILE_NAME in ${TEST_FILE_NAMES}; do
        echo -e "--------------------------------------------------------------------------------\n[$(date)] : Running tests for '${TEST_FILE_NAME}'" | tee -a test.out

        go test -v -timeout 6000s ${TEST_FILE_NAME} | tee -a test.out
      done
  else
      # find the go file based on the filename
      TEST_FILE=`find ${CWD}/**/${TEST_FILE_NAME}`

      echo -e "--------------------------------------------------------------------------------\n[$(date)] : Running tests for '${TEST_FILE}'" | tee -a test.out

      # run a specific test
      #go test -v -timeout 6000s ${TEST_FILE} | tee -a test.out
      #go test -v -timeout 6000s ${TEST_FILE}  . 2>&1 | $(System.DefaultWorkingDirectory)/go-junit-report > ${TEST_FILE/'.go'/'.xml'}
      go test -v -timeout 6000s ${TEST_FILE}  . 2>&1 | go-junit-report > ${TEST_FILE/'.go'/'.xml'}
      
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

  arm_ttk() {
    # run arm-ttk tests
    pushd ./arm-ttk

      az bicep build --file ../../bicep/01_sql/02_deployment/main.bicep

      pwsh -Command \
      "
        Import-Module ./arm-ttk.psd1
        Test-AzTemplate -TemplatePath ../../bicep/01_sql/02_deployment/main.json
        Remove-Item -Force -Path ../../bicep/01_sql/02_deployment/main.json
      "

    # return to the previous directory
    popd
  }

  pester() {
    # run pester tests
    pushd ./pester

      # if the test file is not specified, run for all files
      if [ -z "${1}" ]; then
        pwsh -Command "Invoke-Pester -OutputFile test.xml -OutputFormat NUnitXML"
      else
        TEST_FILE=`find ${1}`

        if [ ! -z "${TEST_FILE}" ]; then
          pwsh -Command "Invoke-Pester -OutputFile test.xml -OutputFormat NUnitXML ${TEST_FILE}"
        fi
      fi

    # return to the previous directory
    popd
  }

  shellspec() {
    # run spec tests
    pushd ./spec

    shellspec -f d

    # return to the previous directory
    popd
  }

  # cd to the tests directory
  pushd ../../IAC/Bicep/test

  if [ -z "${1}" ]; then
    arm_ttk $@
    pester $@
    shellspec $@
  elif [ "${1}" == "arm-ttk" ]; then
    arm_ttk ${2}
  elif [ "${1}" == "pester" ]; then
    pester ${2}
  elif [ "${1}" == "shellspec" ]; then
    shellspec ${2}
  fi

  popd
}
