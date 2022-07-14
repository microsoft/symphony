#!/bin/bash

set -e
NAME="${1:-"$(cat /dev/urandom | env LC_ALL=C tr -dc 'a-z' | fold -w 8 | head -n 1)"}"
LOCATION="${2:-"westus"}"
NNN="${3:-"$(echo $RANDOM | fold -w 3 | head -n 1)"}"

# SUBSCRIPTION_ID=$(az account show --query id --output tsv)

RG_NAME="rg-${NAME}-${NNN}"
CR_NAME="cr${NAME}${NNN}"
KV_NAME="kv-${NAME}-${NNN}"
SP_READER_NAME="sp-reader-${NAME}-${NNN}"
SP_OWNER_NAME="sp-owner-${NAME}-${NNN}"

create_rg() {
    az group create --resource-group "${RG_NAME}" --location "${LOCATION}"
}

create_cr() {
    APP_REPO="https://github.com/dotnet-architecture/eShopOnWeb.git"
    APP_COMMIT="a87f571"
    APP_WEB_NAME="eshopwebmvc"
    APP_WEB_DOCKERFILE="src/Web/Dockerfile"
    APP_API_NAME="eshoppublicapi"
    APP_API_DOCKERFILE="src/PublicApi/Dockerfile"

    az acr create --resource-group "${RG_NAME}" --location "${LOCATION}" --name "${CR_NAME}" --sku Basic

    git clone "${APP_REPO}" "_app"
    pushd "_app"
    git checkout "${APP_COMMIT}"
    az acr build --image "${APP_API_NAME}:${APP_COMMIT}" --registry "${CR_NAME}" --file "${APP_API_DOCKERFILE}" .
    az acr build --image "${APP_WEB_NAME}:${APP_COMMIT}" --registry "${CR_NAME}" --file "${APP_WEB_DOCKERFILE}" .
    popd
    rm -r -f "_app"
}

create_kv() {
    az keyvault create --resource-group "${RG_NAME}" --location "${LOCATION}" --name "${KV_NAME}" --enabled-for-template-deployment true --public-network-access Enabled
}

create_sp() {
    local _display_name="${1}"
    local _role="${2}"
    local _scope="${3}"

    sleep 60
    sp_object=$(az ad sp create-for-rbac --display-name "${_display_name}" --role "${_role}" --scopes "${_scope}")
    echo "${sp_object}" >"${_display_name}.json"

    return "${sp_object}"
}

set_kv_secret() {
    local _name="${1}"
    local _value="${2}"
    local _vault_name="${3}"

    az keyvault secret set --name "${_name}" --value "${_value}" --vault-name "${_vault_name}"
}

rg_id=$(create_rg | jq -r .id)
sp_owner_obj=$(create_sp "${SP_OWNER_NAME}" 'Owner' "${rg_id}")

kv_obj=$(create_kv)
kv_id=$(echo "${kv_obj}" | jq -r .id)
sp_reader_obj=$(create_sp "${SP_READER_NAME}" 'Reader' "${kv_id}")

kv_name=$(echo "${kv_obj}" | jq -r .name)

clientId=$(echo "${sp_reader_obj}" | jq -r .appId)
set_kv_secret 'clientId' "${clientId}" "${kv_name}"

clientSecret=$(echo "${sp_reader_obj}" | jq -r .password)
set_kv_secret 'clientSecret' "${clientId}" "${kv_name}"

subscriptionId=$(az account show --query id --output tsv)
set_kv_secret 'subscriptionId' "${clientId}" "${kv_name}"

tenantId=$(echo "${sp_reader_obj}" | jq -r .tenant)
set_kv_secret 'tenantId' "${clientId}" "${kv_name}"
