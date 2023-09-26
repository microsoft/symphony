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

# copy $prEnvDir to $WORKSPACE_PATH/env/bicep/$ENVIRONMENT_NAME
newEnvDir="$WORKSPACE_PATH/env/bicep/$ENVIRONMENT_NAME"
rm -rf "$newEnvDir"
cp -r "$prEnvDir" "$newEnvDir"

bicepParamFiles=$(find "$newEnvDir" -name "parameters.bicepparam")

# for each entry in bicepParamFiles, modify it with sed
for bicepParamFile in $bicepParamFiles; do
  sed \
    -i.bak \
    "s/param\s*environment\s*=\s*'$PR_ENVIRONMENT_TEMPLATE'/param environment = 'ENVIRONMENT_NAME'/" \
    "$bicepParamFile"

    rm "$bicepParamFile.bak"
done
