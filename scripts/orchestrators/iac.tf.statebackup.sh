#!/bin/bash

source ./iac.tf.sh

echo "Starting backup of ${ENVIRONMENT_NAME} environment remote state. Commit: ${COMMIT_ID}"

# Create backup container name and convert to lower case
backupContainerName=$(echo ${RUN_ID}-${COMMIT_ID} | tr '[:upper:]' '[:lower:]')
backupResourceGroup=$(az storage account list --query "[?name=='$STATE_STORAGE_ACCOUNT_BACKUP'].resourceGroup" -o tsv)

sourceEndPoint=$(az storage account list -g "${STATE_RG}" --query "[?name=='$STATE_STORAGE_ACCOUNT'].{endpointName:primaryEndpoints.blob}" -o tsv)
backupEndpoint=$(az storage account list -g $backupResourceGroup --query "[?name=='$STATE_STORAGE_ACCOUNT_BACKUP'].{endpointName:primaryEndpoints.blob}" -o tsv)

echo "Copying remote state to container ${backupContainerName} in storage account $STATE_STORAGE_ACCOUNT_BACKUP located in resource group ${backupResourceGroup}"

# Checking if azcopy is installed. Otherwise, install it manually because the version that the az cli installs
# has some issues when trying to use the authentication with the az cli

azCopyFilePath=$AZURE_CONFIG_DIR/bin/azcopy
if [ ! -f "$azCopyFilePath" ]; then
    echo "azcopy not found in $azCopyFilePath. Downloading..."
    curl -L https://aka.ms/downloadazcopy-v10-linux -o azcopy_linux_amd64.tar.gz
    tar -xf azcopy_linux_amd64.tar.gz

    echo "Copying azcopy to $azCopyFilePath"
    mkdir -p $AZURE_CONFIG_DIR/bin/
    cp azcopy_linux_amd64*/azcopy $azCopyFilePath
fi


az storage copy --auth-mode login -s ${sourceEndPoint}${STATE_CONTAINER}/${ENVIRONMENT_NAME}/* -d ${backupEndpoint}${STATE_CONTAINER}/${ENVIRONMENT_NAME}/${backupContainerName} --recursive
