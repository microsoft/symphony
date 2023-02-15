#!/usr/bin/env bash

get_keyvault_name() {
    keyvault_name=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "keyvault")
    echo "$keyvault_name"
}
read_kv_secret() {
    local _keyvault_name="${1}"
    local _secret_name="${2}"

    secret_value=$(az keyvault secret show --name "${_secret_name}" --vault-name "${_keyvault_name}" | jq -r '.value')
    echo "${secret_value}"
}

function loadServicePrincipalCredentials() {
    SP_SUBSCRIPTION_NAME="Azure"
    vault_name=$(get_keyvault_name)
    if [ "$vault_name" != "null" ]; then
        _information "$SYMPHONY_ENV_FILE_PATH Found! Loading needed credentials from ${vault_name}"
        SP_SUBSCRIPTION_ID=$(read_kv_secret "${vault_name}" 'readerSubscriptionId')
        SP_TENANT_ID=$(read_kv_secret "${vault_name}" 'readerTenantId')
        SP_ID=$(read_kv_secret "${vault_name}" 'readerClientId')
        SP_SECRET=$(read_kv_secret "${vault_name}" 'readerClientSecret')
    fi  

    if [ -z "$SP_SUBSCRIPTION_ID" ];  then
        _prompt_input "Enter Azure Service Principal Subscription Id" SP_SUBSCRIPTION_ID
    fi

    if [ -z "$SP_CLOUD_ENVIRONMENT" ];  then
        _prompt_input "Enter Azure Cloud Name" SP_CLOUD_ENVIRONMENT
    fi

    if [ -z "$SP_TENANT_ID" ];  then
        _prompt_input "Enter Azure Service Principal Tenant Id" SP_TENANT_ID
    fi

    if [  -z "$SP_ID" ]; then
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