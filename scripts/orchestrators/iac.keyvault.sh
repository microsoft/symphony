#!/bin/bash

OIFS=$IFS
IFS=', '
for secretname in "${SECRETS}"
do
secret=$(az keyvault secret show --name $secretname --vault-name "${KEYVAULT_NAME}" --query "value")
echo "::add-mask::$secret"        
echo "$secretname=$secret" >> $GITHUB_OUTPUT
done
IFS=$OIFS