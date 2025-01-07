#!/bin/bash

mkdir -p "$REPO_DIR/.symphony/logs"
mkdir -p "$REPO_DIR/.symphony/config"

get_prefix() {
  prefix=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "prefix")
  if [ "$prefix" == "null" ]; then
    prefix=$(env </dev/urandom LC_ALL=C tr -dc 'a-z' | fold -w 8 | head -n 1)
    set_json_value "$SYMPHONY_ENV_FILE_PATH" "prefix" "$prefix"
  fi
  echo "$prefix"
}

get_suffix() {
  suffix=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "suffix")
  if [ "$suffix" == "null" ]; then
    suffix=$(echo $RANDOM | fold -w 3 | head -n 1)
    set_json_value "$SYMPHONY_ENV_FILE_PATH" "suffix" "$suffix"
  fi
  echo "$suffix"
}

is_terraform() {
  is_terraform=$(get_json_value "$SYMPHONY_ENV_FILE_PATH" "state_storage_account")
  if [ "$is_terraform" == "null" ]; then
    is_terraform="false"
  fi
  echo "$is_terraform"
}

remove_dependencies() {
  prefix=$(get_prefix)
  suffix=$(get_suffix)
  is_terraform=$(is_terraform)

  RG_NAME="rg-${prefix}-${suffix}"
  KV_NAME="kv-${prefix}-${suffix}"
  SP_NAME="sp-${prefix}-${suffix}"

  SP_APPID=$(az keyvault secret show --name "clientId" --vault-name "$KV_NAME" | jq -r '.value')

  SA_NAME="sa${prefix}${suffix}"

  #Terraform Symphony Resources
  SA_STATE_BACKUP_NAME="sastatebkup${prefix}${suffix}"
  SA_CONTAINER_NAME="tfstate"

  _danger "The following resources will be permanently deleted:"
  echo ""
  _danger "                     Resource Group:  $RG_NAME"
  _danger "                          Key Vault:  $KV_NAME"
  _danger "            Service Principal Name :  $SP_NAME"
  _danger "           Service Principal App Id:  $SP_APPID"
  _danger "                    Storage account:  $SA_NAME"
  if [[ "$is_terraform" != "false" ]]; then
    _danger "      Storage account(State Backup):  $SA_STATE_BACKUP_NAME"
  fi
  echo ""

  local selection=""
  _select_yes_no selection "Destroy Resources (yes/no)?" "true"

  if [[ "$selection" == "yes" ]]; then
    _information "Starting removal of resources"

    _information "Removing Resource Group (${RG_NAME}) and Keyvault ($KV_NAME)"
    az group delete --resource-group "${RG_NAME}" --yes

    _information "Purging Key Vault (${KV_NAME})"
    az keyvault purge -n "$KV_NAME"

    _information "Removing Service Principal $SP_APPID"
    az ad sp delete --id "$SP_APPID"

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
  IS_Terraform=$2

  RG_NAME="rg-${prefix}-${suffix}"
  KV_NAME="kv-${prefix}-${suffix}"
  SP_NAME="sp-${prefix}-${suffix}"
  SA_NAME="sa${prefix}${suffix}"

  #Terraform Symphony Resources
  SA_STATE_BACKUP_NAME="sastatebkup${prefix}${suffix}"
  SA_CONTAINER_NAME="tfstate"

  #Events Symphony Resources
  SA_EVENTS_TABLE_NAME="events"

  _information "The following resources will be Created :"
  _information ""
  _information "                     Resource Group:  $RG_NAME"
  _information "                          Key Vault:  $KV_NAME"
  _information "             Service Principal Name:  $SP_NAME"
  _information "                    Storage account:  $SA_NAME"

  if [[ $IS_Terraform == true ]]; then
    _information "      Storage account(State Backup):  $SA_STATE_BACKUP_NAME"
  fi
  echo ""

  local selection=""
  _select_yes_no selection "Create Resources (yes/no)?" "true"

  if [[ "$selection" == "yes" ]]; then
    _information "Starting creation of resources"

    # Create RG
    _information "Creating Resource Group: ${RG_NAME}"
    create_rg

    # Create KV
    _information "Creating Key Vault: ${KV_NAME}"
    kv_id=$(create_kv | jq -r .id)

    # Create KV role assignment for the current logged in user
    local _current_az_user=$(az ad signed-in-user show --query id -o tsv)
    create_kv_role_assignment "Key Vault Administrator" "${_current_az_user}" "${KV_NAME}"

    # Create SA
    _information "Creating Storage Account: ${SA_NAME}"
    create_sa "${SA_NAME}" "Standard_LRS" "SystemAssigned"

    # Create Events SA table
    _information "Creating Events Storage Account Table: ${SA_EVENTS_TABLE_NAME} for Storage Account:${SA_NAME}"
    create_sa_table "${SA_EVENTS_TABLE_NAME}" "${SA_NAME}"

    # Save Events SA details to KV
    echo "Saving Events Storage Account (${SA_NAME}) to Key Vault secret 'eventsStorageAccount'."
    set_kv_secret 'eventsStorageAccount' "${SA_NAME}" "${KV_NAME}"

    # Save Events Table name to KV
    echo "Saving Storage Account Events Table(${SA_EVENTS_TABLE_NAME}) to Key Vault secret 'eventsTableName'."
    set_kv_secret 'eventsTableName' "${SA_EVENTS_TABLE_NAME}" "${KV_NAME}"

    if [[ $IS_Terraform == true ]]; then
      # Create State SA container
      _information "Creating Storage Account Container: ${SA_CONTAINER_NAME} for Storage Account:${SA_NAME}"
      create_sa_container "${SA_CONTAINER_NAME}" "${SA_NAME}"

      # Push Test mocks to state SA
      _information "Push test mocked state files to state SA: ${SA_CONTAINER_NAME} for Storage Account:${SA_NAME}"
      store_file_in_sa_container "./../../IAC/Terraform/test/terraform/mocked_deployment.tfstate" "Test_Mocks/02_storage/01_deployment.tfstate" "${SA_NAME}" "${SA_CONTAINER_NAME}"

      # Create backup State SA
      _information "Creating Backup Storage Account: ${SA_STATE_BACKUP_NAME}"
      create_sa "${SA_STATE_BACKUP_NAME}" "Standard_LRS" "SystemAssigned"

      # Create Backup State SA container
      _information "Creating Backup Storage Account Container: ${SA_CONTAINER_NAME} for Storage Account:${SA_STATE_BACKUP_NAME}"
      create_sa_container "${SA_CONTAINER_NAME}" "${SA_STATE_BACKUP_NAME}"

      # Save State SA details to KV
      echo "Saving State Storage Account (${SA_NAME}) to Key Vault secret 'stateStorageAccount'."
      set_kv_secret 'stateStorageAccount' "${SA_NAME}" "${KV_NAME}"

      # Save State Backup SA details to KV
      echo "Saving State Backup Storage Account (${SA_STATE_BACKUP_NAME}) to Key Vault secret 'stateStorageAccountBackup'."
      set_kv_secret 'stateStorageAccountBackup' "${SA_STATE_BACKUP_NAME}" "${KV_NAME}"

      # Save Container name to KV
      echo "Saving Storage Account State Container(${SA_CONTAINER_NAME}) to Key Vault secret 'stateContainer'."
      set_kv_secret 'stateContainer' "${SA_CONTAINER_NAME}" "${KV_NAME}"

      # Save state RG name to KV
      echo "Saving state Resource Group Name (${RG_NAME}) to Key Vault secret 'stateRg'."
      set_kv_secret 'stateRg' "${RG_NAME}" "${KV_NAME}"
    fi

    local create_sp=""
    _select_yes_no create_sp "Create Service Principal (yes/no)?" "true"

    local sp_client_id=""
    local sp_tenant_id=""
    local sp_sub_id=""

    if [[ "$create_sp" == "yes" ]]; then

      # Create SP and assing to subscription level
      _information "Creating Service Principal: ${SP_NAME}"
      sp_obj=$(create_sp "${SP_NAME}" 'Owner' "/subscriptions/${SP_SUBSCRIPTION_ID}")
      sp_appid=$(echo "$sp_obj" | jq -r '.appId')

      # Save SP details to KV
      sp_client_id=$(echo "${sp_obj}" | jq -r .appId)
      sp_sub_id=${SP_SUBSCRIPTION_ID}
      sp_tenant_id=$(echo "${sp_obj}" | jq -r .tenant)
    else
      echo "Use Existing Service Principal"
      _prompt_input "Enter Principal Subscription Id" sp_sub_id
      _prompt_input "Enter Service Principal tenant Id" sp_tenant_id
      _prompt_input "Enter Service Principal Id" sp_client_id
    fi

    # Save SP details to KV
    _information "Saving Service Principal (${SP_NAME}) to Key Vault secret 'clientId'."
    set_kv_secret 'clientId' "${sp_client_id}" "${KV_NAME}"

    _information "Saving Service Principal (${SP_NAME}) to Key Vault secret 'subscriptionId'."
    set_kv_secret 'subscriptionId' "${sp_sub_id}" "${KV_NAME}"

    _information "Saving Service Principal (${SP_NAME}) to Key Vault secret 'tenantId'."
    set_kv_secret 'tenantId' "${sp_tenant_id}" "${KV_NAME}"

    _information "Assign Key Vault Secrets User role for Service Principal (${SP_NAME}) to Key Vault ${KV_NAME}"
    create_kv_role_assignment "Key Vault Secrets User" "${sp_client_id}" "${KV_NAME}"

    _information "Assign Storage Table Data Contributor role for Service Principal (${SP_NAME}) to Storage Account ${SA_NAME}"
    create_sa_role_assignment "Storage Table Data Contributor" "${sp_client_id}" "${SA_NAME}"

    # Store values in Symphonyenv.json
    set_json_value "$SYMPHONY_ENV_FILE_PATH" "resource_group" "$RG_NAME"
    set_json_value "$SYMPHONY_ENV_FILE_PATH" "keyvault" "$KV_NAME"
    set_json_value "$SYMPHONY_ENV_FILE_PATH" "service_principal" "$SP_NAME"
    set_json_value "$SYMPHONY_ENV_FILE_PATH" "state_storage_account" "$SA_NAME"
    if [[ $IS_Terraform == true ]]; then
      set_json_value "$SYMPHONY_ENV_FILE_PATH" "backupstate_storage_account" "$SA_STATE_BACKUP_NAME"
      set_json_value "$SYMPHONY_ENV_FILE_PATH" "state_container" "$SA_CONTAINER_NAME"
    fi

    _success "Symphony resources have been provisioned! Details on resources are in $SYMPHONY_ENV_FILE_PATH "
    rgLink="$(get_resource_group_link)"
    _success "You can view the resources created in the Azure Portal $rgLink"
  else
    _information "Provision Aborted!"
  fi

}

get_resource_group_link() {
  portal_link=$(az cloud show | jq -r '.endpoints.portal')

  echo "${portal_link}/#@/resource/subscriptions/$SP_SUBSCRIPTION_ID/resourceGroups/$RG_NAME/overview"
}

create_rg() {
  az group create --resource-group "${RG_NAME}" --location "${LOCATION}"
}

create_kv() {
  az keyvault create --resource-group "${RG_NAME}" --location "${LOCATION}" --name "${KV_NAME}" --enabled-for-template-deployment true --public-network-access Enabled --enable-rbac-authorization
}

create_kv_role_assignment() {
  create_role_assignment "${1}" "${2}" "${3}" "keyvault"
}

create_sa_role_assignment() {
  create_role_assignment "${1}" "${2}" "${3}" "storage account"
}

create_role_assignment() {
  local _role="${1}"
  local _sp_app_id="${2}"
  local _name="${3}"
  local _az_sub_commands="${4}"

  local _scope=$(az ${_az_sub_commands} show --name "${_name}" --query id -o tsv)
  az role assignment create --role "${_role}" --assignee "${_sp_app_id}" --scope "${_scope}"

  _information "sleep for 20 seconds to allow the role assignment to take effect"
  sleep 20
}

create_sp() {
  local _display_name="${1}"
  local _role="${2}"
  local _scope="${3}"

  sleep 60
  sp_object=$(az ad sp create-for-rbac --display-name "${_display_name}" --role "${_role}" --scopes "${_scope}")

  echo "${sp_object}"
}

create_sa() {
  local _display_name="${1}"
  local _sku="${2}"
  local _identity="${3}"
  sleep 60
  az storage account create --name "${_display_name}" --resource-group "${RG_NAME}" --location "${LOCATION}" --sku "${_sku}" --identity-type "${_identity}"
}

create_sa_container() {
  local _display_name="${1}"
  local _account_name="${2}"

  az storage container create --name "${_display_name}" --account-name "${_account_name}"
}

store_file_in_sa_container() {
  local _file_path="${1}"
  local _display_name="${2}"
  local _account_name="${3}"
  local _container_name="${4}"

  az storage blob upload --account-name "${_account_name}" --container-name "${_container_name}" --file "${_file_path}" --name "${_display_name}"
}

create_sa_table() {
  local _table_name="${1}"
  local _account_name="${2}"

  az storage table create --name "${_table_name}" --account-name "${_account_name}"
}

set_kv_secret() {
  local _name="${1}"
  local _value="${2}"
  local _vault_name="${3}"

  az keyvault secret set --name "${_name}" --value "${_value}" --vault-name "${_vault_name}"
}
