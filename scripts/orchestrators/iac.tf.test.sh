#!/bin/bash

source ./tests.runner.sh
pushd "${WORKSPACE_PATH}/IAC/Terraform/test/terraform"

# install junit
echo "install go-junit-report"
go install github.com/jstemmer/go-junit-report@latest

# set test vars
export resource_group_name="${STATE_RG}"
export storage_account_name="${STATE_STORAGE_ACCOUNT}"
export container_name="${STATE_CONTAINER}"

# retrieve client_id, subscription_id, tenant_id from logged in user
azaccount=$(az account show)
client_id=$(echo $azaccount | jq -r .user.name)
subscription_id=$(echo $azaccount | jq -r .id)
tenant_id=$(echo $azaccount | jq -r .tenantId)

# These env variables must be set in order for cross-tenant deployments to work
export ARM_SUBSCRIPTION_ID=$subscription_id
export ARM_CLIENT_ID=$client_id
export ARM_TENANT_ID=$tenant_id
export ARM_USE_OIDC=true
export ARM_USE_AZUREAD=true
export ARM_STORAGE_USE_AZUREAD=true

export TF_VAR_target_tenant_id=$tenant_id
export TF_VAR_target_subscription_id=$subscription_id

if [[ "${TEST_TAG}" == "module_tests" ]]; then
  echo "Run tests with tag = module_tests"
  terraform module_test true
elif [[ "${TEST_TAG}" == "e2e_test" ]]; then
  echo "Run tests with tag = e2e_test"
  terraform e2e_test true
else
  SAVEIFS=${IFS}
  IFS=$'\n'
  tests=($(find . -type f -name '*end_test.go' -print))
  IFS=${SAVEIFS}

  for test in "${tests[@]}"; do
    terraform ${test/'./'/''}
  done
fi

popd
