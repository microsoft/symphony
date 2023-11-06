#!/usr/bin/env bash

get_keyvault_name() {
  keyvault_name=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "keyvault")
  echo "$keyvault_name"
}
read_kv_secret() {
  local _secret_name="${1}"

  secret_value=$(az keyvault secret show --name "${_secret_name}" --vault-name "${SYMPHONY_KV_NAME}" | jq -r '.value')
  echo "${secret_value}"
}

function loadServicePrincipalCredentials() {
  if [[ -f "$SYMPHONY_ENV_FILE_PATH" ]]; then
    SYMPHONY_KV_NAME=$(get_keyvault_name)
    if [ "$SYMPHONY_KV_NAME" != "null" ]; then
      _information "$SYMPHONY_ENV_FILE_PATH Found! Loading needed credentials from ${SYMPHONY_KV_NAME}"
      SP_SUBSCRIPTION_ID=$(read_kv_secret 'readerSubscriptionId')
      SP_TENANT_ID=$(read_kv_secret 'readerTenantId')
      SP_ID=$(read_kv_secret 'readerClientId')
      SP_SECRET=$(read_kv_secret 'readerClientSecret')
    fi
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

  if [ -z "$SP_SECRET" ]; then
    _prompt_input "Enter Azure Service Principal Client Secret" SP_SECRET
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
    SYMPHONY_KV_NAME=$(get_keyvault_name)
    SYMPHONY_RG_NAME=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "resource_group")
    SYMPHONY_ACR_NAME=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "container_registry")
    SYMPHONY_SA_STATE_NAME=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "state_storage_account")
  fi

  if [ -z "$SYMPHONY_KV_NAME" ]; then
    _prompt_input "Enter Symphony KeyVault Name" SYMPHONY_KV_NAME
  fi

  if [ -z "$SYMPHONY_RG_NAME" ]; then
    _prompt_input "Enter Symphony Resource Group Name" SYMPHONY_RG_NAME
  fi

  if [ -z "$SYMPHONY_ACR_NAME" ]; then
    _prompt_input "Enter Symphony Container Registry Name" SYMPHONY_ACR_NAME
  fi

  if [ "$IACTOOL" != "bicep" ]; then
    if [ -z "$SYMPHONY_SA_STATE_NAME" ]; then
      _prompt_input "Enter Symphony State Storage Account Name" SYMPHONY_SA_STATE_NAME
    fi
  fi
}
