#!/bin/bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR"/../utilities/shell_logger.sh

azlogin() {
  local subscription_id="${1}"
  local tenant_id="${2}"
  local client_id="${3}"
  local client_secret="${4}"
  local cloud_name="${5}"

  # AzureCloud AzureChinaCloud AzureUSGovernment AzureGermanCloud
  az cloud set --name "${cloud_name}"
  az login --service-principal --username="${client_id}" --password="${client_secret}" --tenant="${tenant_id}"
  az account set --subscription "${subscription_id}"

  export ARM_CLIENT_ID="${client_id}"
  export ARM_CLIENT_SECRET="${client_secret}"
  export ARM_SUBSCRIPTION_ID="${subscription_id}"
  export ARM_TENANT_ID="${tenant_id}"

  # https://www.terraform.io/docs/providers/azurerm/index.html#environment
  # environment - (Optional) The Cloud Environment which should be used.
  # Possible values are public, usgovernment, german, and china. Defaults to public.
  # This can also be sourced from the ARM_ENVIRONMENT environment variable.

  if [ "${cloud_name}" == 'AzureCloud' ]; then
    export ARM_ENVIRONMENT="public"
    export AZURE_ENVIRONMENT="AzurePublicCloud"
  elif [ "${cloud_name}" == 'AzureUSGovernment' ]; then
    export ARM_ENVIRONMENT="usgovernment"
    export AZURE_ENVIRONMENT="AzureUSGovernmentCloud"
  elif [ "${cloud_name}" == 'AzureChinaCloud' ]; then
    export ARM_ENVIRONMENT="AzureChinaCloud"
    export AZURE_ENVIRONMENT="AzurePublicCloud"
  elif [ "${cloud_name}" == 'AzureGermanCloud' ]; then
    export ARM_ENVIRONMENT="german"
    export AZURE_ENVIRONMENT="AzureGermanCloud"
  else
    _error "Unknown cloud. Check documentation https://www.terraform.io/docs/providers/azurerm/index.html#environment"
    return 1
  fi
}

load_dotenv() {
  local dotenv_file_path="${1:-".env"}"

  if [[ -f "${dotenv_file_path}" ]]; then
    _information "Loading .env file: ${dotenv_file_path}"
    set -o allexport
    source "${dotenv_file_path}"
    set +o allexport
  fi
}
