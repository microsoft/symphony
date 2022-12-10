#!/usr/bin/env bash

function loadServicePrincipalCredentials() {
    if [ -z "$SP_SUBSCRIPTION_ID" ];  then
        _prompt_input "Enter Azure Subscription Id" SP_SUBSCRIPTION_ID
    fi

    if [ -z "$SP_SUBSCRIPTION_NAME" ];  then
        _prompt_input "Enter Azure Subscription Name" SP_SUBSCRIPTION_NAME
    fi

    if [ -z "$SP_CLOUD_ENVIRONMENT" ];  then
        _prompt_input "Enter Azure Cloud Name" SP_CLOUD_ENVIRONMENT
    fi

    if [ -z "$SP_TENANT_ID" ];  then
        _prompt_input "Enter Azure Tenant Id" SP_TENANT_ID
    fi

    if [  -z "$SP_ID" ]; then
        _prompt_input "Enter Azure Service Principal Client Id" SP_ID
    fi

    if [ -z "$SP_SECRET" ]; then
        _prompt_input "Enter Azure Service Principal Client Secret" SP_SECRET
    fi
    
}

function printEnvironment() {
    echo ""
    _information "********************************************************************"
    _information "           Command:   $command"
    if [[ "$command" == "pipeline" ]]; then
        _information "      Orchestrator:   $ORCHESTRATOR"
        _information "          IAC Tool:   $IACTOOL"
    fi
    _information " Subscription Name:   $SP_SUBSCRIPTION_NAME"
    _information "   Subscription Id:   $SP_SUBSCRIPTION_ID"
    _information "            Tenant:   $SP_TENANT_ID"
    _information "         Client Id:   $SP_ID"
    _information "Client Environment:   $SP_CLOUD_ENVIRONMENT"
    _information "********************************************************************"
    echo ""
}