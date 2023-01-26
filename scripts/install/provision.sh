#!/bin/bash

mkdir -p "$REPO_DIR/.symphony/logs"
mkdir -p "$REPO_DIR/.symphony/config"


get_prefix(){
    prefix=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "prefix")
    if [ "$prefix" == "null" ]; then
        prefix=$(< /dev/urandom env LC_ALL=C tr -dc 'a-z' | fold -w 8 | head -n 1)
        set_json_value  "$SYMPHONY_ENV_FILE_PATH" "prefix" "$prefix"
    fi
    echo "$prefix"
}

get_suffix(){
    suffix=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "suffix")
    if [ "$suffix" == "null" ]; then
      suffix=$(echo $RANDOM | fold -w 3 | head -n 1)
      set_json_value  "$SYMPHONY_ENV_FILE_PATH" "suffix" "$suffix"
    fi
    echo "$suffix"
}

remove_dependencies() {
    prefix=$(get_prefix)
    suffix=$(get_suffix)

    RG_NAME="rg-${prefix}-${suffix}"
    CR_NAME="cr${prefix}${suffix}"
    KV_NAME="kv-${prefix}-${suffix}"
    SP_READER_NAME="sp-reader-${prefix}-${suffix}"
    SP_OWNER_NAME="sp-owner-${prefix}-${suffix}"
    
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

    local selection=""
    _prompt_input "Destroy Resources (yes/no)?" selection "true"
    echo ""

    if [[ "$selection" == "yes" ]]; then
        _information "Starting removal of resources"
        
        _information "Removing Resource Group (${RG_NAME}), Azure Container Registry ($CR_NAME) and Keyvault ($KV_NAME)"
        az group delete --resource-group "${RG_NAME}" --yes 

        _information "Purging Key Vault (${KV_NAME})"
        az keyvault purge -n "$KV_NAME"

        _information "Removing Service Principal (Reader) $SP_READER_APPID"
        az ad sp delete --id "$SP_READER_APPID"

        _information "Service Principal (Owner) $SP_OWNER_APPID"
        az ad sp delete --id "$SP_OWNER_APPID"

        _information "Resources Removed"
    else
        _danger "Destroy Aborted!"
    fi
}

# provision entrypoint
deploy_dependencies() {
    prefix=$(get_prefix)
    LOCATION="$1"
    suffix=$(get_suffix)

    RG_NAME="rg-${prefix}-${suffix}"
    CR_NAME="cr${prefix}${suffix}"
    KV_NAME="kv-${prefix}-${suffix}"
    SP_READER_NAME="sp-reader-${prefix}-${suffix}"
    SP_OWNER_NAME="sp-owner-${prefix}-${suffix}"

    _information "The following resources will be Created :"
    _information ""
    _information "                     Resource Group:  $RG_NAME"
    _information "                          Key Vault:  $KV_NAME"
    _information "                 Container Registry:  $CR_NAME"
    _information "    Service Principal Name (Reader):  $SP_READER_NAME"
    _information "     Service Principal Name (Owner):  $SP_OWNER_NAME"
    echo ""

    local selection=""
    _prompt_input "Create Resources (yes/no)?" selection "true"
    echo ""

    if [[ "$selection" == "yes" ]]; then
        _information "Starting creation of resources"
        
         # Create RG
        echo "Creating RG: ${RG_NAME}"
        create_rg

        # Create CR
        echo "Creating CR: ${CR_NAME}"
        create_cr

        # Create KV
        echo "Creating KV: ${KV_NAME}"
        kv_id=$(create_kv | jq -r .id)

        local create_owner_sp=""
        _prompt_input "Create Owner SP (yes/no)?" create_owner_sp "true"
        echo ""

        local sp_owner_client_id=""
        local sp_owner_client_secret=""
        local sp_owner_tenant_id=""
        local sp_owner_sub_id=""
 
        if [[ "$create_owner_sp" == "yes" ]]; then
       
            # Create Owner SP and assing to subscription level
            echo "Creating Owner SP: ${SP_OWNER_NAME}"
            sp_owner_obj=$(create_sp "${SP_OWNER_NAME}" 'Owner' "/subscriptions/${SP_SUBSCRIPTION_ID}")
            sp_owner_appid=$(echo "$sp_owner_obj" | jq -r '.appId')

            # Save Owner SP details to KV
            sp_owner_client_id=$(echo "${sp_owner_obj}" | jq -r .appId)     
            sp_owner_client_secret=$(echo "${sp_owner_obj}" | jq -r .password)
            sp_owner_sub_id=${SP_SUBSCRIPTION_ID}
            sp_owner_tenant_id=$(echo "${sp_owner_obj}" | jq -r .tenant)       
        else
            echo "Use Existing Service Principal for Owner"            
            _prompt_input "Enter Owner Service Principal Subscription Id" sp_owner_sub_id
            _prompt_input "Enter Owner Service Principal tenant Id" sp_owner_tenant_id
            _prompt_input "Enter Owner Service Principal Id" sp_owner_client_id
            _prompt_input "Enter Owner Service Principal secret" sp_owner_client_secret
        fi

        # Save Owner SP details to KV
        echo "Saving Owner SP (${SP_OWNER_NAME}) clientId to KV"
        set_kv_secret 'clientId' "${sp_owner_client_id}" "${KV_NAME}"

        echo "Saving Owner SP (${SP_OWNER_NAME}) clientSecret to KV"
        set_kv_secret 'clientSecret' "${sp_owner_client_secret}" "${KV_NAME}"

        echo "Saving Owner SP (${SP_OWNER_NAME}) subscriptionId to KV"
        set_kv_secret 'subscriptionId' "${sp_owner_sub_id}" "${KV_NAME}"

        echo "Saving Owner SP (${SP_OWNER_NAME}) tenantId to KV"
        set_kv_secret 'tenantId' "${sp_owner_tenant_id}" "${KV_NAME}"       

        # Create Reader SP and assign to KV only
        echo "Creating Reader SP: ${SP_READER_NAME}"
        sp_reader_obj=$(create_sp "${SP_READER_NAME}" 'Reader' "${kv_id}")
        sp_reader_appid=$(echo "$sp_reader_obj" | jq -r '.appId')

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

        #Store values in Symphonyenv.json
        set_json_value "$SYMPHONY_ENV_FILE_PATH" "resource_group" "$RG_NAME"
        set_json_value "$SYMPHONY_ENV_FILE_PATH" "keyvault" "$KV_NAME"
        set_json_value "$SYMPHONY_ENV_FILE_PATH" "container_registry" "$CR_NAME"
        set_json_value "$SYMPHONY_ENV_FILE_PATH" "reader_service_principal" "$SP_READER_NAME"
        set_json_value "$SYMPHONY_ENV_FILE_PATH" "reader_service_principal" "$SP_READER_NAME"
        set_json_value "$SYMPHONY_ENV_FILE_PATH" "owner_service_principal" "$SP_OWNER_NAME"

        _success "Symphony resources have been provisioned! Details on resources are in $SYMPHONY_ENV_FILE_PATH "
    else
        _information "Provision Aborted!"
    fi

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

    _information "Waiting for ACR creation before pushing images"
    sleep 60   
    
    git clone "${APP_REPO}" "_app"
    pushd "_app" || exit
        git checkout "${APP_COMMIT}"
        az acr build --image "${APP_API_NAME}:${APP_COMMIT}" --registry "${CR_NAME}" --file "${APP_API_DOCKERFILE}" .
        az acr build --image "${APP_WEB_NAME}:${APP_COMMIT}" --registry "${CR_NAME}" --file "${APP_WEB_DOCKERFILE}" .
    popd || exit
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
