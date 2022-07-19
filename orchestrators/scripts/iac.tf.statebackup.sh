#!/bin/bash

source ./iac.tf.sh
azlogin "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" 'AzureCloud'

echo "Starting backup of ${ENVIRONMENT_NAME} environment remote state. Commit: ${COMMIT_ID}"

# Create backup container name and convert to lower case
backupContainerName=$(echo ${RUN_ID}-${COMMIT_ID} | tr '[:upper:]' '[:lower:]')
backupResourceGroup=$(az storage account list --query "[?name=='$STATE_STORAGE_ACCOUNT_BACKUP'].resourceGroup" -o tsv)

sourceEndPoint=$(az storage account list -g "${STATE_RG}" --query "[?name=='$STATE_STORAGE_ACCOUNT'].{endpointName:primaryEndpoints.blob}" -o tsv)
backupEndpoint=$(az storage account list -g $backupResourceGroup --query "[?name=='$STATE_STORAGE_ACCOUNT_BACKUP'].{endpointName:primaryEndpoints.blob}" -o tsv)

echo "Copying remote state to container ${backupContainerName} in storage account $STATE_STORAGE_ACCOUNT_BACKUP located in resource group ${backupResourceGroup}"
az storage copy -s ${sourceEndPoint}${STATE_CONTAINER}/${ENVIRONMENT_NAME}/* -d ${backupEndpoint}${STATE_CONTAINER}/${ENVIRONMENT_NAME}/${backupContainerName} --recursive
