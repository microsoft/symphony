#!/usr/bin/env bash

# todo:
#   - Setting EXCLUDED_FOLDERS excludes that single deployment
#   - Renaming a layer so that it starts with __ skips the entire layer
 
#   - add readme
#   - add script to build harness dynamically

declare WORKSPACE_PATH=$(pwd)
declare RUN_ID=1
declare ENVIRONMENT_NAME="dev"
declare LOCATION_NAME="westus"
declare STATE_STORAGE_ACCOUNT="sastatedngwzqxq134" 
declare STATE_CONTAINER="tfstate" 
declare STATE_RG="rg-dngwzqxq-134"

declare EXCLUDED_FOLDERS="02_sql/02_foo"

source .symphony/test_auth.sh

# Ensure these enviornment variables exist prior to running the script.
# export ARM_SUBSCRIPTION_ID=""
# export ARM_TENANT_ID=""
# export ARM_CLIENT_ID=""
# export ARM_CLIENT_SECRET=""

pushd $WORKSPACE_PATH/scripts/orchestrators
    source ./iac.tf.previewdeploy.sh
popd