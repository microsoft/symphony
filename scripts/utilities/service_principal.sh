#!/usr/bin/env bash

function loadServicePrincipalCredentials() {
  if [[ -f "$SYMPHONY_ENV_FILE_PATH" ]]; then
    SP_SUBSCRIPTION_ID=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "sp_sub_id")
    SP_TENANT_ID=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "sp_tenant_id")
    SP_ID=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "sp_client_id")
  fi

  if [ -z "$SP_SUBSCRIPTION_ID" ]; then
    _prompt_input "Enter Azure Service Principal Subscription Id" SP_SUBSCRIPTION_ID
  fi

  if [ -z "$SP_CLOUD_ENVIRONMENT" ]; then
    _prompt_input "Enter Azure Cloud Name" SP_CLOUD_ENVIRONMENT
  fi

  if [ -z "$SP_TENANT_ID" ]; then
    _prompt_input "Enter Azure Service Principal Tenant Id" SP_TENANT_ID
  fi

  if [ -z "$SP_ID" ]; then
    _prompt_input "Enter Azure Service Principal Client Id" SP_ID
  fi
}

# command is a global variable declared in the entrypoint script.
function printEnvironment() {
  echo ""
  _information "********************************************************************"
  _information "           Command:   $command"
  if [[ "$command" == "pipeline" ]]; then
    _information "      Orchestrator:   $ORCHESTRATOR"
    _information "          IAC Tool:   $IACTOOL"
  fi
  _information "   Subscription Id:   $SP_SUBSCRIPTION_ID"
  _information "            Tenant:   $SP_TENANT_ID"
  _information "         Client Id:   $SP_ID"
  _information "Client Environment:   $SP_CLOUD_ENVIRONMENT"
  _information "********************************************************************"
  echo ""
}

function load_symphony_env() {
  if [[ -f "$SYMPHONY_ENV_FILE_PATH" ]]; then
    SYMPHONY_RG_NAME=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "resource_group")
    SYMPHONY_SA_STATE_NAME=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "state_storage_account")
    SP_SUBSCRIPTION_ID=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "sp_sub_id")
    SP_TENANT_ID=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "sp_tenant_id")
    SP_ID=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "sp_client_id")
    SYMPHONY_EVENTS_TABLE_NAME=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "events_table_name")
    SYMPHONY_EVENTS_STORAGE_ACCOUNT=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "events_storage_account")
    SYMPHONY_SA_STATE_NAME_BACKUP=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "backupstate_storage_account")
    SYMPHONY_STATE_CONTAINER=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "state_container")

  fi

  if [ -z "$SYMPHONY_RG_NAME" ]; then
    _prompt_input "Enter Symphony Resource Group Name" SYMPHONY_RG_NAME
  fi

  if [ "$IACTOOL" != "bicep" ]; then
    if [ -z "$SYMPHONY_SA_STATE_NAME" ]; then
      _prompt_input "Enter Symphony State Storage Account Name" SYMPHONY_SA_STATE_NAME
    fi
  fi
}
