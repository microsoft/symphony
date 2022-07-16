#!/bin/bash

set -e
NAME="${1:-"$(cat /dev/urandom | env LC_ALL=C tr -dc 'a-z' | fold -w 8 | head -n 1)"}"
LOCATION="${2:-"westus"}"
NNN="${3:-"$(echo $RANDOM | fold -w 3 | head -n 1)"}"

SUBSCRIPTION_ID=$(az account show --query id --output tsv)

RG_NAME="rg-${NAME}-${NNN}"
CR_NAME="cr${NAME}${NNN}"
KV_NAME="kv-${NAME}-${NNN}"
SP_READER_NAME="sp-reader-${NAME}-${NNN}"
SP_OWNER_NAME="sp-owner-${NAME}-${NNN}"

create_rg() {
    az group create --resource-group "${RG_NAME}" --location "${LOCATION_NAME}"
}

create_cr() {
    APP_REPO="https://github.com/dotnet-architecture/eShopOnWeb.git"
    APP_COMMIT="a87f571"
    APP_WEB_NAME="eshopwebmvc"
    APP_WEB_DOCKERFILE="src/Web/Dockerfile"
    APP_API_NAME="eshoppublicapi"
    APP_API_DOCKERFILE="src/PublicApi/Dockerfile"

    az acr create --resource-group "${RG_NAME}" --location "${LOCATION_NAME}" --name "${CR_NAME}" --sku Basic

    git clone "${APP_REPO}" "_app"
    pushd "_app"
    git checkout "${APP_COMMIT}"
    az acr build --image "${APP_API_NAME}:${APP_COMMIT}" --registry "${CR_NAME}" --file "${APP_API_DOCKERFILE}" .
    az acr build --image "${APP_WEB_NAME}:${APP_COMMIT}" --registry "${CR_NAME}" --file "${APP_WEB_DOCKERFILE}" .
    popd
    rm -r -f "_app"
}

create_kv() {
    az keyvault create --resource-group "${RG_NAME}" --location "${LOCATION_NAME}" --name "${KV_NAME}" --enabled-for-template-deployment true --public-network-access Enabled
}

create_sp() {
    local _display_name="${1}"
    local _role="${2}"
    local _scope="${3}"

    sleep 60
    sp_object=$(az ad sp create-for-rbac --display-name "${_display_name}" --role "${_role}" --scopes "${_scope}")
    echo "${sp_object}" >"${_display_name}.json"

    echo "${sp_object}"
}

set_kv_secret() {
    local _name="${1}"
    local _value="${2}"
    local _vault_name="${3}"

    az keyvault secret set --name "${_name}" --value "${_value}" --vault-name "${_vault_name}"
}

# Create RG
echo "Creating RG: ${RG_NAME}"
create_rg

# Create CR
echo "Creating CR: ${CR_NAME}"
create_cr

# Create Owner SP and assing to subscription level
echo "Creating Owner SP: ${SP_OWNER_NAME}"
sp_owner_obj=$(create_sp "${SP_OWNER_NAME}" 'Owner' "/subscriptions/${SUBSCRIPTION_ID}")

# Create KV
echo "Creating KV: ${KV_NAME}"
kv_id=$(create_kv | jq -r .id)

# Save Owner SP details to KV
echo "Saving Owner SP (${SP_OWNER_NAME}) clientId to KV"
clientId=$(echo "${sp_owner_obj}" | jq -r .appId)
set_kv_secret 'clientId' "${clientId}" "${KV_NAME}"

echo "Saving Owner SP (${SP_OWNER_NAME}) clientSecret to KV"
clientSecret=$(echo "${sp_owner_obj}" | jq -r .password)
set_kv_secret 'clientSecret' "${clientSecret}" "${KV_NAME}"

echo "Saving Owner SP (${SP_OWNER_NAME}) subscriptionId to KV"
set_kv_secret 'subscriptionId' "${SUBSCRIPTION_ID}" "${KV_NAME}"

echo "Saving Owner SP (${SP_OWNER_NAME}) tenantId to KV"
tenantId=$(echo "${sp_owner_obj}" | jq -r .tenant)
set_kv_secret 'tenantId' "${tenantId}" "${KV_NAME}"

# Create Reader SP and assing to KV only
echo "Creating Reader SP: ${SP_READER_NAME}"
sp_reader_obj=$(create_sp "${SP_READER_NAME}" 'Reader' "${kv_id}")

# Save Reader SP details to KV
echo "Saving Reader SP (${SP_READER_NAME}) readerClientId to KV"
clientId=$(echo "${sp_reader_obj}" | jq -r .appId)
set_kv_secret 'readerClientId' "${clientId}" "${KV_NAME}"

echo "Saving Reader SP (${SP_READER_NAME}) readerClientSecret to KV"
clientSecret=$(echo "${sp_reader_obj}" | jq -r .password)
set_kv_secret 'readerClientSecret' "${clientSecret}" "${KV_NAME}"

echo "Saving Reader SP (${SP_READER_NAME}) readerSubscriptionId to KV"
set_kv_secret 'readerSubscriptionId' "${SUBSCRIPTION_ID}" "${KV_NAME}"

echo "Saving Reader SP (${SP_READER_NAME}) readerTenantId to KV"
tenantId=$(echo "${sp_reader_obj}" | jq -r .tenant)
set_kv_secret 'readerTenantId' "${tenantId}" "${KV_NAME}"
