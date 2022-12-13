#!/bin/bash

mkdir -p $REPO_DIR/.symphony/logs
mkdir -p $REPO_DIR/.symphony/config

get_prefix(){
    if [[ ! -f $REPO_DIR/.symphony/config/.prefix ]];then
        NAME="${1:-"$(cat /dev/urandom | env LC_ALL=C tr -dc 'a-z' | fold -w 8 | head -n 1)"}"
        echo $NAME >  $REPO_DIR/.symphony/config/.prefix
    fi
    prefix=$(cat $REPO_DIR/.symphony/config/.prefix)
    echo $prefix
}

get_suffix(){
    if [[ ! -f $REPO_DIR/.symphony/config/.suffix ]];then
        NNN="${3:-"$(echo $RANDOM | fold -w 3 | head -n 1)"}"
        echo $NNN >  $REPO_DIR/.symphony/config/.suffix
    fi
    suffix=$(cat $REPO_DIR/.symphony/config/.suffix)
    echo $suffix
}

remove_dependencies() {
    NAME=$(get_prefix)
    LOCATION="${2:-"westus"}"
    NNN=$(get_suffix)

    RG_NAME="rg-${NAME}-${NNN}"
    CR_NAME="cr${NAME}${NNN}"
    KV_NAME="kv-${NAME}-${NNN}"
    SP_READER_NAME="sp-reader-${NAME}-${NNN}"
    SP_OWNER_NAME="sp-owner-${NAME}-${NNN}"
    
    SP_READER_APPID=$(az keyvault secret show --name "clientId" --vault-name "$KV_NAME" | jq -r '.value')
    SP_OWNER_APPID=$(az keyvault secret show --name "readerClientId" --vault-name "$KV_NAME" | jq -r '.value')

    _danger "The following resources will be permanently deleted:"
    echo ""
    _danger "                     Resource Group:  $RG_NAME"
    _danger "           Azure Container Registry:  $CR_NAME"
    _danger "                          Key Vault:  $KV_NAME"
    _danger "    Service Principal Name (Reader):  $SP_READER_NAME"
    _danger "   Service Principal App Id(Reader):  $SP_READER_APPID"
    _danger "     Service Principal Name (Owner):  $SP_OWNER_NAME"
    _danger "   Service Principal App Id (Owner):  $SP_OWNER_APPID"
    echo ""


    _prompt_input "Destroy Resources (yes/no)?" selection "true"
    echo ""

    if [[ "$selection" == "yes" ]]; then
        _information "Starting removal of resources"
        
        _information "Removing Resource Group (${RG_NAME}), Azure Container Registry ($CR_NAME) and Keyvault ($KV_NAME)"
        az group delete --resource-group "${RG_NAME}" --yes --no-wait

        _information "Removing Service Principal (Reader) $SP_READER_APPID"
        az ad sp delete --id $SP_READER_APPID

        _information "Service Principal (Owner) $SP_OWNER_APPID"
        az ad sp delete --id $SP_OWNER_APPID

        _information "Resources Removed"
        _information "Note the keyvault $KV_NAME has been soft deleted. In order to reprovision, either purge or restore the keyvault."
    else
        _danger "Destroy Aborted!"
    fi
}
# provision entrypoint
deploy_dependencies() {
    NAME=$(get_prefix)
    LOCATION="${2:-"westus"}"
    NNN=$(get_suffix)

    RG_NAME="rg-${NAME}-${NNN}"
    CR_NAME="cr${NAME}${NNN}"
    KV_NAME="kv-${NAME}-${NNN}"
    SP_READER_NAME="sp-reader-${NAME}-${NNN}"
    SP_OWNER_NAME="sp-owner-${NAME}-${NNN}"


    # Create RG
    echo "Creating RG: ${RG_NAME}"
    create_rg

    # Create CR
    echo "Creating CR: ${CR_NAME}"
    create_cr

    # Create Owner SP and assing to subscription level
    echo "Creating Owner SP: ${SP_OWNER_NAME}"
    sp_owner_obj=$(create_sp "${SP_OWNER_NAME}" 'Owner' "/subscriptions/${SP_SUBSCRIPTION_ID}")
    sp_owner_appid=$(echo $sp_owner_obj | jq -r '.appId')

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
    set_kv_secret 'subscriptionId' "${SP_SUBSCRIPTION_ID}" "${KV_NAME}"

    echo "Saving Owner SP (${SP_OWNER_NAME}) tenantId to KV"
    tenantId=$(echo "${sp_owner_obj}" | jq -r .tenant)
    set_kv_secret 'tenantId' "${tenantId}" "${KV_NAME}"

    # Create Reader SP and assing to KV only
    echo "Creating Reader SP: ${SP_READER_NAME}"
    sp_reader_obj=$(create_sp "${SP_READER_NAME}" 'Reader' "${kv_id}")
    sp_reader_appid=$(echo $sp_reader_obj | jq -r '.appId')

    # Save Reader SP details to KV
    echo "Saving Reader SP (${SP_READER_NAME}) readerClientId to KV"
    clientId=$(echo "${sp_reader_obj}" | jq -r .appId)
    set_kv_secret 'readerClientId' "${clientId}" "${KV_NAME}"

    echo "Saving Reader SP (${SP_READER_NAME}) readerClientSecret to KV"
    clientSecret=$(echo "${sp_reader_obj}" | jq -r .password)
    set_kv_secret 'readerClientSecret' "${clientSecret}" "${KV_NAME}"

    echo "Saving Reader SP (${SP_READER_NAME}) readerSubscriptionId to KV"
    set_kv_secret 'readerSubscriptionId' "${SP_SUBSCRIPTION_ID}" "${KV_NAME}"

    echo "Saving Reader SP (${SP_READER_NAME}) readerTenantId to KV"
    tenantId=$(echo "${sp_reader_obj}" | jq -r .tenant)
    set_kv_secret 'readerTenantId' "${tenantId}" "${KV_NAME}"

}

create_rg() {
    az group create --resource-group "${RG_NAME}" --location "${LOCATION}"
}

create_cr() {
    APP_REPO="https://github.com/dotnet-architecture/eShopOnWeb.git"
    APP_COMMIT="a72dd77"
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

    echo "${sp_object}"
}

set_kv_secret() {
    local _name="${1}"
    local _value="${2}"
    local _vault_name="${3}"

    az keyvault secret set --name "${_name}" --value "${_value}" --vault-name "${_vault_name}"
}
