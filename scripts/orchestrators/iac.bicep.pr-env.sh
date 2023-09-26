#!/bin/bash

### TODO: Change this to use the new bicepparam files

# Syntax: ./iac.bicep.pr-env.sh

# if ENVIRONMENT_NAME is empty, fail
if [ -z "${ENVIRONMENT_NAME}" ]; then
  echo "ENVIRONMENT_NAME is empty"
  exit 1
fi

if [ -z "${PR_ENVIRONMENT_TEMPLATE}" ]; then
  echo "PR_ENVIRONMENT_TEMPLATE is empty"
  exit 1
fi

prEnvDir="${WORKSPACE_PATH}/env/bicep/${PR_ENVIRONMENT_TEMPLATE}"
# if the env/bicep/$PR_ENVIRONMENT_TEMPLATE folder does not exist, fail
if [ ! -d "$prEnvDir" ]; then
  echo "$prEnvDir folder does not exist"
  exit 1
fi

prEnvJsonFile="$prEnvDir/parameters.json"
# if the env/bicep/pr/parameters.json file does not exist, fail
if [ ! -f "$prEnvJsonFile" ]; then
  echo "$prEnvJsonFile file does not exist"
  exit 1
fi

envKeyPath='.parameters.environment.value'

# load the content of the if the env/bicep/$PR_ENVIRONMENT_TEMPLATE/parameters.json file
currentEnv=$(jq -r $envKeyPath < "$prEnvJsonFile")

# check if currentEnv is empty or is null
if [ -z "$currentEnv" ] || [ "$currentEnv" == "null" ]; then  
  echo "missing $envKeyPath in $prEnvJsonFile"
  exit 1
fi

# copy $prEnvDir to $WORKSPACE_PATH/env/bicep/$ENVIRONMENT_NAME
newEnvDir="$WORKSPACE_PATH/env/bicep/$ENVIRONMENT_NAME"
rm -rf "$newEnvDir"
cp -r "$prEnvDir" "$newEnvDir"

# update the value of the environment parameter in the parameters.json file
newEnvJsonFile="$newEnvDir/parameters.json"

jq "$envKeyPath = \"$ENVIRONMENT_NAME\"" "$newEnvJsonFile" \
  > tmp.json && mv tmp.json "$newEnvJsonFile"
