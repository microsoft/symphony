#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR"/../../../utilities/shell_logger.sh
source "$SCRIPT_DIR"/../../../utilities/shell_inputs.sh
source "$SCRIPT_DIR"/../../../utilities/http.sh

########################################################################################
#
# Configure Azure DevOps Project for Symphony
#
########################################################################################
function load_inputs {
  _information "Load AzDo Configurations"

  local _host_type_group_name=''

  if [ -z "$AZDO_ORG_URI" ]; then
    _prompt_input "Enter Azure Devops URL 'e.g. https://dev.azure.com/MYORG' or 'https://<CUSTOM_SERVER_URL>/MYCOLLECTION'" AZDO_ORG_URI
  fi

  if [[ $AZDO_ORG_URI == *".azure.com"* ]] || [[ $AZDO_ORG_URI == *".visualstudio.com"* ]]; then
    export INSTALL_TYPE='PAAS'
    _host_type_group_name='Organization name (i.e. MYORG)'
  else
    export INSTALL_TYPE='Server'
    _host_type_group_name='Project Collection name (i.e. MYCOLLECTION)'
  fi

  _information "AzDo Install Type: $INSTALL_TYPE"

  if [ -z "$AZDO_ORG_NAME" ]; then
    _prompt_input "Enter existing Azure Devops $_host_type_group_name" AZDO_ORG_NAME
  fi

  if [ -z "$AZDO_PROJECT_NAME" ]; then
    _prompt_input "Enter the name of a new Azure Devops Project to create" AZDO_PROJECT_NAME
  fi

  if [ -z "$AZDO_PAT" ]; then
    # If on PAAS, ask to use az cli credentials instead of an actual PAT
    if [ "$INSTALL_TYPE" == "PAAS" ]; then

      local use_az_cli_credentials_azdo=""
      _select_yes_no use_az_cli_credentials_azdo "Use Azure CLI credentials for Azure DevOps" "true"

      if [ "$use_az_cli_credentials_azdo" == "yes" ]; then
        _information "Retrieving a short lived access token for AzDO..."

        # If AZDO_TENANT_ID is set, use it
        if [ -n "$AZDO_TENANT_ID" ]; then
          tenant_id=$AZDO_TENANT_ID
        else
          # Try to get the managedByTenantId first
          local tenant_id=$(az account show --query managedByTenants[0].tenantId -o tsv)

          # If that is empty, fallback to the tenantId
          if [ -z "$tenant_id" ]; then
              tenant_id=$(az account show --query tenantId -o tsv)
          fi
        fi

        _information "Using tenant_id: $tenant_id"

        local azdo_resource_id="499b84ac-1321-427f-aa17-267ca6975798"

        AZDO_PAT=$(az account get-access-token --tenant $tenant_id --resource $azdo_resource_id --query accessToken --output tsv)

        _information "Retrieved an access token for AzDO via az cli!"
      fi
    fi
  fi

  if [ -z "$AZDO_PAT" ]; then
    _prompt_input "Enter Azure Devops PAT" AZDO_PAT
  fi
}

function configure_repo {
  _information "Create Project AzDo"

  local project_source_control='git'
  local project_process_tempalte='Agile'
  local _token=$(echo -n ":${AZDO_PAT}" | base64 -w 0)

  _information "Starting project creation for project ${AZDO_PROJECT_NAME}"

  # 1. GET Get all processes to get template id
  # AzDo Service     : Processes - Get https://docs.microsoft.com/rest/api/azure/devops/core/processes/get?view=azure-devops-rest-5.1
  # GET https://{instance}/{collection}/_apis/process/processes/{processId}?api-version=5.0
  _uri=$(_set_api_version "${AZDO_ORG_URI}/_apis/process/processes?api-version=" '5.1' '5.1')
  _debug "Requesting process templates"
  _response=$(request_get "${_uri}" "application/json; charset=utf-8" "Basic ${_token}")
  echo "$_response" >"$AZDO_TEMP_LOG_PATH/pt.json"

  if [[ "$_response" == *"Access Denied: The Personal Access Token used has expired"* ]]; then
    _error "Authentication Error Personal Access Token used has expired!"
    exit 1
  fi

  if [[ "$_response" == *"Azure DevOps Services | Sign In"* ]]; then
    _error "Authentication Error Requesting process templates. Please ensure the PAT is valid."
    exit 1
  fi

  if [ -z "$_response" ]; then
    _error "Error Requesting process templates. Please ensure the PAT is valid and has not expired."
    exit 1
  fi
  _processTemplateId=$(jq <"$AZDO_TEMP_LOG_PATH/pt.json" -r '.value[] | select(.name == "'"$project_process_tempalte"'") | .id')

  # 2. Create Project
  # AzDo Service     : Projects - Create https://docs.microsoft.com/rest/api/azure/devops/core/projects/create?view=azure-devops-rest-5.1
  # POST https://{{coreServer}}/{{organization}}/_apis/projects?api-version={{api-version}}
  _payload=$(sed <"$SCRIPT_DIR/templates/project-create.json" 's~__AZDO_PROJECT_NAME__~'"${AZDO_PROJECT_NAME}"'~' | sed 's~__AZDO_PROJECT_SOURCE_CONTROL__~'"$project_source_control"'~' | sed 's~__AZDO_PROCESS_TEMPLATE_ID__~'"${_processTemplateId}"'~')
  _uri=$(_set_api_version "${AZDO_ORG_URI}/_apis/projects?api-version=" '5.1' '5.1')

  _debug "Creating project"
  # 2. POST Create project
  _response=$(
    request_post \
      "${_uri}" \
      "${_payload}" \
      "application/json; charset=utf-8" \
      "Basic ${_token}"
  )
  echo "$_response" >"$AZDO_TEMP_LOG_PATH/cp.json"
  local _createProjectTypeKey=$(echo "$_response" | jq -r '.typeKey')
  if [ "$_createProjectTypeKey" = "ProjectAlreadyExistsException" ]; then
    _error "Error creating project in org '${AZDO_ORG_URI}. \nProject repo '${AZDO_PROJECT_NAME}' already exists."
    exit 1
  fi

  _debug_log_post "$_uri" "$_response" "$_payload"

  #When going through rest apis, there is a timing issue from project create to querying the repo properties.
  sleep 15

  # Fetch The list of projects to get this project's id
  # https://docs.microsoft.com/rest/api/azure/devops/core/Projects/List?view=azure-devops-server-rest-5.0
  # GET https://{instance}/{collection}/_apis/projects?api-version=5.0
  _uri="${AZDO_ORG_URI}/_apis/projects?api-version=5.0"
  _response=$(request_get "$_uri" "application/json; charset=utf-8" "Basic ${_token}")
  echo "$_response" >"$AZDO_TEMP_LOG_PATH/get-project-id.json"
  AZDO_PROJECT_ID=$(jq <"$AZDO_TEMP_LOG_PATH/get-project-id.json" -r '.value[] | select (.name == "'"${AZDO_PROJECT_NAME}"'") | .id')

  # 3. GET Repos Git Url and Repo Id's
  # AzDo Service     : Repositories - Get Repository https://docs.microsoft.com/rest/api/azure/devops/git/repositories/get%20repository?view=azure-devops-rest-5.1
  # GET https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}?api-version=5.1

  _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/git/repositories/${AZDO_PROJECT_NAME}?api-version=" '5.1' '5.1')
  _debug "Fetching ${AZDO_PROJECT_NAME} repository information"
  _response=$(request_get "${_uri}" "application/json; charset=utf-8" "Basic ${_token}")
  _debug_log_get "$_uri" "$_response"

  echo "$_response" >"$AZDO_TEMP_LOG_PATH/${AZDO_PROJECT_NAME}-ri.json"
  CODE_REPO_GIT_HTTP_URL=$(jq <"$AZDO_TEMP_LOG_PATH/${AZDO_PROJECT_NAME}-ri.json" -c -r '.remoteUrl')
  CODE_REPO_ID=$(jq <"$AZDO_TEMP_LOG_PATH/${AZDO_PROJECT_NAME}-ri.json" -c -r '.id')
  _debug "$CODE_REPO_GIT_HTTP_URL"
  echo "${AZDO_PROJECT_NAME} Git Repo remote URL: $CODE_REPO_GIT_HTTP_URL"

  # Configure remote for local git repo
  git init
  git branch -m main
  git remote add origin "$CODE_REPO_GIT_HTTP_URL"

  _success "Project '${AZDO_PROJECT_NAME}' created."
}

function configure_runners {
  # Replace in all files in ./.azure-pipelines "runs-on: ubuntu-latest" with "runs-on: self-hosted"
  if [[ "$OSTYPE" == "darwin"* ]]; then
      for file in ./.azure-pipelines/*; do
          sed -i '' -E 's/([[:space:]]*)vmImage: \$\(agentImage\)([[:space:]]*)/\1name: 'Default'\2/g' "$file"
      done
  else
      for file in ./.azure-pipelines/*; do
          sed -i -E 's/([[:space:]]*)vmImage: \$\(agentImage\)([[:space:]]*)/\1name: 'Default'\2/g' "$file"
      done
  fi

  # Verify that required variables exist
  local REQUIRED_VARS=(\
      AZDO_ORG_URI \
      AZDO_PAT \
      RUNNERS_RESOURCE_GROUP \
      RUNNERS_LOCATION \
      RUNNERS_SUBNET \
      RUNNERS_PUBLIC_KEY_PATH)
  for var in "${REQUIRED_VARS[@]}"; do
      if [[ -z "${!var}" ]]; then
          _error "The variable '$var' is not defined. Aborting."
          exit 1
      fi
  done

  # Validate that the file exists
  if [[ ! -f "$RUNNERS_PUBLIC_KEY_PATH" ]]; then
      _error "The specified public key file '$RUNNERS_PUBLIC_KEY_PATH' does not exist. Aborting."
      exit 1
  fi

  # Optional parameter: VM size (default: Standard_D2s_v3)
  RUNNERS_AZURE_VM_SIZE=${RUNNERS_AZURE_VM_SIZE:-Standard_D2s_v3}

  # Optional parameter: Number of runners to launch (default: 1)
  RUNNERS_COUNT=${RUNNERS_COUNT:-1}

  # Optional parameter: Image (default: Ubuntu2404)
  RUNNERS_AZURE_IMAGE=${RUNNERS_AZURE_IMAGE:-Ubuntu2404}

  # Optional parameter: VM name (default: symphony-azdo-runner)
  RUNNERS_VM_NAME=${RUNNERS_VM_NAME:-symphony-azdo-runner}-${AZDO_PROJECT_NAME}

  # Optional parameter: VM username (default: azureuser)
  RUNNERS_VM_USERNAME=${RUNNERS_VM_USERNAME:-azureuser}

  local token=$AZDO_PAT

  # Generate the cloud-init file (cloud-init.yaml)
  cat > cloud-init.yaml <<EOF
  #cloud-config
  package_update: true

  packages:
    - curl
    - tar
    - uidmap
    - unzip
    - docker.io
    - build-essential

  write_files:
    - path: /agent-install.sh
      permissions: '0777'
      content: |
          #!/usr/bin/env bash

          cd /home/$RUNNERS_VM_USERNAME

          # Enable Docker
          sudo systemctl enable --now docker
          sudo usermod -aG docker $RUNNERS_VM_USERNAME

          # Install AzDO runner

          for i in \$(seq 1 ${RUNNERS_COUNT}); do
              RUNNER_DIR="/home/$RUNNERS_VM_USERNAME/azdo-runner-\$i"
              echo "Configuring runner in \$RUNNER_DIR..."
              mkdir -p "\$RUNNER_DIR"
              cd "\$RUNNER_DIR"

              # Download a fixed version of the runner
              RUNNER_VERSION="4.251.0"
              curl -O -L "https://vstsagentpackage.azureedge.net/agent/\${RUNNER_VERSION}/vsts-agent-linux-x64-\${RUNNER_VERSION}.tar.gz"
              tar xzf "vsts-agent-linux-x64-\${RUNNER_VERSION}.tar.gz"

              # Configure the runner non-interactively using its respective token
              ./config.sh --unattended --url "${AZDO_ORG_URI}" --auth pat --token "${token}" --pool "Default" --agent "agent-\$i" --acceptTeeEula

              # Install the service
              sudo ./svc.sh install

              # Start the runner in the background
              sudo ./svc.sh start

              # Return to the home directory for the next iteration
              cd /home/$RUNNERS_VM_USERNAME
          done
  runcmd:
    - sudo -u $RUNNERS_VM_USERNAME /agent-install.sh
EOF

  echo "cloud-init.yaml file generated."

  # Create the VM using Azure CLI with the specified parameters and cloud-init
  _information "Creating the VM in Azure..."
  vm_create_command="az vm create \
    --resource-group \"$RUNNERS_RESOURCE_GROUP\" \
    --name \"$RUNNERS_VM_NAME\" \
    --location \"$RUNNERS_LOCATION\" \
    --image \"$RUNNERS_AZURE_IMAGE\" \
    --size \"$RUNNERS_AZURE_VM_SIZE\" \
    --admin-username \"$RUNNERS_VM_USERNAME\" \
    --ssh-key-values \"@$RUNNERS_PUBLIC_KEY_PATH\" \
    --subnet \"$RUNNERS_AZURE_SUBNET\" \
    --nsg \"\" \
    --custom-data cloud-init.yaml"

  _debug "Running command: $vm_create_command"
  eval $vm_create_command

  rm cloud-init.yaml

  _information "The VM creation request has been submitted."
}

function configure_credentials {
  _information "Configure Service Connections"
  _create_arm_svc_connection
}

function create_pipelines_terraform() {
  _information "Creating variable group for Terraform pipelines"

  local variablesInGroup

  variablesInGroup=$(_get_pipeline_var_defintion stateRg $SYMPHONY_RG_NAME true)
  variablesInGroup="$variablesInGroup, $(_get_pipeline_var_defintion stateStorageAccount $SYMPHONY_SA_STATE_NAME true)"
  variablesInGroup="$variablesInGroup, $(_get_pipeline_var_defintion stateContainer $SYMPHONY_STATE_CONTAINER true)"
  variablesInGroup="$variablesInGroup, $(_get_pipeline_var_defintion stateStorageAccountBackup $SYMPHONY_SA_STATE_NAME_BACKUP true)"

  _create_variable_group "symphony" "${variablesInGroup}"

  _information "Creating Azure Pipelines "
  local pipelineVariables

  pipelineVariables=$(_get_pipeline_var_defintion environmentName dev true)

  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion goVersion 1.18.1 true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion terraformVersion 1.11.0 true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion runLayerTest false true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion runBackupState true true)"
  _create_pipeline "CI-Deploy" "/.azure-pipelines/pipeline.ci.terraform.yml" "Deploy" "${pipelineVariables}" "${AZDO_PROJECT_NAME}"

  pipelineVariables=$(_get_pipeline_var_defintion environmentName dev true)
  _create_pipeline "Destroy" "/.azure-pipelines/pipeline.destroy.terraform.yml" "Destroy" "${pipelineVariables}" "${AZDO_PROJECT_NAME}"

}

function create_pipelines_bicep() {
  _information "Creating Azure Pipelines "
  local pipelineVariables

  pipelineVariables=$(_get_pipeline_var_defintion environmentName dev true)
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion locationName westus true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion excludedFolders , true)"
  _create_pipeline "CI-Deploy" "/.azure-pipelines/pipeline.ci.bicep.yml" "Deploy" "${pipelineVariables}" "${AZDO_PROJECT_NAME}"

  pipelineVariables=$(_get_pipeline_var_defintion environmentName dev true)
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion locationName westus true)"
  _create_pipeline "Destroy" "/.azure-pipelines/pipeline.destroy.bicep.yml" "Destroy" "${pipelineVariables}" "${AZDO_PROJECT_NAME}"

}

function _create_arm_svc_connection() {
  # https://docs.microsoft.com/rest/api/azure/devops/serviceendpoint/endpoints/create?view=azure-devops-rest-5.1#endpointauthorization
  # https://docs.microsoft.com/rest/api/azure/devops/serviceendpoint/endpoints/create?view=azure-devops-server-rest-5.0
  # Create Azure RM Service connection

  _information "Creating AzureRM service connection"

  # Get the management endpoint for whatever cloud we are provisioning for.
  _get_management_endpoint

  _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/serviceendpoint/endpoints?api-version=" '5.1-preview.2' '5.1-preview.2')
  _payload=$(_create_svc_connection_payload)
  echo "${_payload}" >"$AZDO_TEMP_LOG_PATH/casc_payload.json"

  local _token=$(echo -n ":${AZDO_PAT}" | base64 -w 0)
  _response=$(
    request_post \
      "${_uri}" \
      "${_payload}" \
      "application/json; charset=utf-8" \
      "Basic ${_token}"
  )

  echo "$_response" >"$AZDO_TEMP_LOG_PATH/casc.json"
  _debug_log_post "$_uri" "$_response" "$_payload"

  sc_id=$(jq <"$AZDO_TEMP_LOG_PATH/casc.json" -r .id)
  sc_issuer=$(jq <"$AZDO_TEMP_LOG_PATH/casc.json" -r '.authorization.parameters.workloadIdentityFederationIssuer')
  sc_subject=$(jq <"$AZDO_TEMP_LOG_PATH/casc.json" -r '.authorization.parameters.workloadIdentityFederationSubject')


  # Configuring federated identity for Azure DevOps Pipelines, based on repo name and environment name
  parameters=$(cat <<EOF
  {
    "name": "symphony-credential-${AZDO_PROJECT_ID}",
    "issuer": "${sc_issuer}",
    "subject": "${sc_subject}",
    "description": "Symphony credential for Azure DevOps Pipelines",
    "audiences": [
        "api://AzureADTokenExchange"
    ]
  }
EOF
  )
  _debug "Creating Federated Credential for: ${sc_id}"
  az ad app federated-credential create --id "$SP_ID" --parameters "$parameters"

  _debug "Service Connection ID: ${sc_id}"
  sleep 10
  _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/serviceendpoint/endpoints/${sc_id}?api-version=" '5.1-preview.2' '5.1-preview.1')
  _response=$(request_get "$_uri" "application/json; charset=utf-8" "Basic ${_token}")

  echo "$_response" >"$AZDO_TEMP_LOG_PATH/isready.json"

  _isReady=$(jq <"$AZDO_TEMP_LOG_PATH"/isready.json -r '.isReady')
  if [ "$_isReady" != true ]; then
    _error "Error creating AzureRM service connection"
  fi

  # https://docs.microsoft.com/rest/api/azure/devops/build/authorizedresources/authorize%20project%20resources?view=azure-devops-rest-5.1
  # https://docs.microsoft.com/rest/api/azure/devops/build/authorizedresources/authorize%20project%20resources?view=azure-devops-server-rest-5.0
  # Authorize the service connection for all pipelines.
  _information "Authorizing service connection for all pipelines."

  _payload=$(sed <"$SCRIPT_DIR/templates/authorized-resources.json" 's~__SERVICE_CONNECTION_ID__~'"${sc_id}"'~')
  _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/build/authorizedresources?api-version=" '5.1-preview.1' '5.1-preview.1')

  _response=$(
    request_patch \
      "${_uri}" \
      "${_payload}" \
      "application/json; charset=utf-8" \
      "Basic ${_token}"
  )

  _debug_log_patch "$_uri" "$_response" "$_payload"

  _success "AzureRM service connection created and authorized"
  #az devops service-endpoint update --org ${AZDO_ORG_URI} --project ${AZDO_PROJECT_NAME} --enable-for-all true --id ${scId}
}

function _create_azdo_svc_connection() {
  _information "Creating azdo service connection"
  # AzDo Service     : Service Endpoint - Create https://docs.microsoft.com/rest/api/azure/devops/serviceendpoint/endpoints/create?view=azure-devops-rest-5.1

  _templateFile=''

  if [ "$INSTALL_TYPE" == "PAAS" ]; then
    _templateFile="$SCRIPT_DIR/templates/sc-ado-paas.json"
  else
    _templateFile="$SCRIPT_DIR/templates/sc-ado-server.json"
  fi

  _debug "starting payload $_templateFile"

  _payload=$(sed <"$_templateFile" 's~__ADO_ORG_NAME__~'"${AZDO_ORG_NAME}"'~' | sed 's~__ADO_ORG_URI__~'"${AZDO_ORG_URI}"'~' | sed 's~__ADO_PAT__~'"${AZDO_PAT}"'~')

  _debug "done payload"
  _debug_json "$_payload"

  _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/serviceendpoint/endpoints?api-version=" '5.1-preview.1' '5.1-preview.1')
  local _token=$(echo -n ":${AZDO_PAT}" | base64 -w 0)

  _response=$(
    request_post \
      "${_uri}" \
      "${_payload}" \
      "application/json; charset=utf-8" \
      "Basic ${_token}"
  )

  echo "$_response" >"$AZDO_TEMP_LOG_PATH/scado.json"
  _debug_log_post "$_uri" "$_response" "$_payload"

  _scId=$(jq <"$AZDO_TEMP_LOG_PATH/scado.json" -r '.id')
  _isReady=$(jq <"$AZDO_TEMP_LOG_PATH/scado.json" -r '.isReady')

  if [ "$_isReady" != true ]; then
    _error "Error creating azdo service connection"
  fi

  _success "azdo service connection created.  service connection id: ${_scId}"

  _payload=$(sed <"$SCRIPT_DIR/templates/sc-ado-auth.json" 's~__SC_ADO_ID__~'"${_scId}"'~')
  _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/pipelines/pipelinePermissions/endpoint/${_scId}?api-version=" '5.1-preview' '5.1-preview')
  _response=$(
    request_patch \
      "${_uri}" \
      "${_payload}" \
      "application/json; charset=utf-8" \
      "Basic ${_token}"
  )
  echo "$_response" >"$AZDO_TEMP_LOG_PATH/sc-ado-auth.json"

  _debug_log_patch "$_uri" "$_response" "$_payload"

  _allPipelinesAuthorized=$(jq <"$AZDO_TEMP_LOG_PATH/sc-ado-auth.json" -r '.allPipelines.authorized')

  if [ "$_allPipelinesAuthorized" == true ]; then
    _success "azdo service connection authorized for all pipelines"
  fi
}

function _create_variable_group {

  _information "Create Variable Group"

  local _template_file="$SCRIPT_DIR/templates/variable-group-create.json"
  local _name="${1}"
  local _variables=${2}

  local _payload=$(
    sed <"${_template_file}" 's~__ADO_VARIABLE_GROUP_NAME__~'"${_name}"'~' |
    sed 's~__ADO_VARIABLES__~'"${_variables}"'~' |
    sed 's~__ADO_PROJECT_ID__~'"${AZDO_PROJECT_ID}"'~' |
    sed 's~__ADO_PROJECT_NAME__~'"${AZDO_PROJECT_NAME}"'~'
  )

  local _uri=$(_set_api_version "${AZDO_ORG_URI}/_apis/distributedtask/variablegroups?api-version=" '7.1' '7.1')

  local _token=$(echo -n ":${AZDO_PAT}" | base64 -w 0)
  local _response=$(request_post "${_uri}" "${_payload}" "application/json; charset=utf-8" "Basic ${_token}")

  echo "$_payload" >"$AZDO_TEMP_LOG_PATH/${_name}-cvg-payload.json"
  echo "$_response" >"$AZDO_TEMP_LOG_PATH/${_name}-cvg.json"

  _debug_log_post "$_uri" "$_response" "$_payload"

  _success "Created Variable Group ${_name}"
}

function _create_pipeline {

  _information "Create Pipeline AzDo"

  # AzDo Service     : Definitions - Create https://docs.microsoft.com/rest/api/azure/devops/build/definitions/create?view=azure-devops-rest-5.1
  # POST https://dev.azure.com/{organization}/{project}/_apis/build/definitions?api-version=5.1
  # usage: _create_pipeline storageinit "/azure-pipelines/pipeline.storageinit.yml"
  _information "Creating pipelines..."

  local _template_file="$SCRIPT_DIR/templates/pipeline-create.json"
  local _name="${1}"
  local _yaml_path=${2}
  local _folder_path=${3}
  local _variables=${4}
  local _pipelineRepoName=${5}

  local _agent_queue=$(_get_agent_pool_queue)
  local _agent_pool_queue_id=$(echo "$_agent_queue" | jq -c -r '.agent_pool_queue_id')
  local _agent_pool_queue_name=$(echo "$_agent_queue" | jq -c -r '.agent_pool_queue_name')

  # Update the Agent for AzDO Server
  if [ "$INSTALL_TYPE" == "Server" ]; then
    local _yaml_file="${_yaml_path:1}"

    sed -i 's/agentImage/agentName/g' $_yaml_file
    sed -i 's/value: "ubuntu-latest"/value: "Default"/g' $_yaml_file
    sed -i 's/vmImage:/name:/g' $_yaml_file
  fi

  # Ensure the Agent Pool is setup correctly
  local _branch_name="main"
  local _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/build/definitions?api-version=" '5.1' '5.1')

  local _payload=$(
    sed <"${_template_file}" 's~__ADO_PIPELINE_NAME__~'"${_name}"'~' |
      sed 's~__ADO_PIPELINE_FOLDER_PATH__~'"${_folder_path}"'~' |
      sed 's~__ADO_PIPELINE_REPO_BRANCH__~'"${_branch_name}"'~' |
      sed 's~__ADO_PIPELINE_REPO_NAME__~'"${_pipelineRepoName}"'~' |
      sed 's~__ADO_PIPELINE_YAML_FILE_PATH__~'"${_yaml_path}"'~' |
      sed 's~__ADO_PIPELINE_VARIABLES__~'"${_variables}"'~' |
      sed 's~__ADO_POOL_ID__~'"${_agent_pool_queue_id}"'~' |
      sed 's~__ADO_POOL_NAME__~'"${_agent_pool_queue_name}"'~' |
      sed 's~__AZDO_ORG_URI__~'"${AZDO_ORG_URI}"'~'
  )
  local _token=$(echo -n ":${AZDO_PAT}" | base64 -w 0)
  local _response=$(request_post "${_uri}" "${_payload}" "application/json; charset=utf-8" "Basic ${_token}")

  echo "$_payload" >"$AZDO_TEMP_LOG_PATH/${_name}-cp-payload.json"
  echo "$_response" >"$AZDO_TEMP_LOG_PATH/${_name}-cp.json"

  _debug_log_post "$_uri" "$_response" "$_payload"

  local _createPipelineTypeKey=$(jq <"$AZDO_TEMP_LOG_PATH/${_name}-cp.json" -r '.typeKey')

  if [ "$_createPipelineTypeKey" == "DefinitionExistsException" ]; then
    _error "Pipeline ${_name} already exists."
  fi

  local _pipeId=$(jq <"$AZDO_TEMP_LOG_PATH/${_name}-cp.json" -r '.id')

  # Authorize Pipeline
  _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/pipelines/pipelinePermissions/queue/${_agent_pool_queue_id}?api-version=" '5.1-preview.1' '5.1-preview.1')
  _debug "${_uri}"
  _payload=$(
    sed <"$SCRIPT_DIR/templates/pipeline-authorize.json" 's~__PIPELINE_ID__~'"${_pipeId}"'~'
  )
  _response=$(request_patch "${_uri}" "${_payload}" "application/json; charset=utf-8" "Basic ${_token}")
  echo "$_payload" >"$AZDO_TEMP_LOG_PATH/${_name}-cp-authorize-payload.json"
  echo "$_response" >"$AZDO_TEMP_LOG_PATH/${_name}-cp-authorize.json"

  if [ "$_pipeId" != null ]; then
    if [ "${_name}" == "env.compile" ]; then
      envCompilePipelineId=$_pipeId
    fi
    _success "Created Pipeline ${_name} - id:${_pipeId}"
  fi

  # Authorize Terraform-Code Repo Access for Pipeline
  _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/pipelines/pipelinePermissions/repository/${AZDO_PROJECT_ID}.${CODE_REPO_ID}?api-version=" '5.1-preview.1' '5.1-preview.1')
  _debug "${_uri}"
  _payload=$(
    sed <"$SCRIPT_DIR/templates/pipeline-authorize.json" 's~__PIPELINE_ID__~'"${_pipeId}"'~'
  )
  _response=$(request_patch "${_uri}" "${_payload}" "application/json; charset=utf-8" "Basic ${_token}")
  echo "$_payload" >"$AZDO_TEMP_LOG_PATH/${_name}-cp-authorize-code-repo-payload.json"
  echo "$_response" >"$AZDO_TEMP_LOG_PATH/${_name}-cp-authorize-code-repo.json"

  _success "Created Pipeline ${_name} - id:${_pipeId}"
}

function _create_svc_connection_payload() {
  local _payload

  local AZDO_SC_AZURERM_NAME='symphony'

  if [ "$INSTALL_TYPE" == "PAAS" ]; then
    if [ "$USER_SECRET" == "true" ]; then
      _template="$SCRIPT_DIR/templates/service-connection-create-paas.json"
      _payload=$(
        cat "$_template" |
          sed 's~__SERVICE_PRINCIPAL_ID__~'"${SP_ID}"'~' |
          sed 's@__SERVICE_PRINCIPAL_KEY__@'"${SP_SECRET}"'@' |
          sed 's~__SERVICE_PRINCIPAL_TENANT_ID__~'"${SP_TENANT_ID}"'~' |
          sed 's~__CLOUD_ENVIRONMENT__~'"${SP_CLOUD_ENVIRONMENT}"'~' |
          sed 's~__SUBSCRIPTION_ID__~'"${SP_SUBSCRIPTION_ID}"'~' |
          sed 's~__SUBSCRIPTION_NAME__~'"${SP_SUBSCRIPTION_NAME}"'~' |
          sed 's~__SERVICE_CONNECTION_NAME__~'"${AZDO_SC_AZURERM_NAME}"'~' |
          sed 's~__PROJECT_ID__~'"${AZDO_PROJECT_ID}"'~' |
          sed 's~__PROJECT_NAME__~'"${AZDO_PROJECT_NAME}"'~' |
          sed 's~__MANAGEMENT_URI__~'"${MANAGEMENT_URI}"'~'
      )
    else
      _template="$SCRIPT_DIR/templates/sc-ado-paas-federated.json"
      _payload=$(
        cat "$_template" |
          sed 's~__SERVICE_PRINCIPAL_ID__~'"${SP_ID}"'~' |
          sed 's~__SERVICE_PRINCIPAL_TENANT_ID__~'"${SP_TENANT_ID}"'~' |
          sed 's~__SUBSCRIPTION_ID__~'"${SP_SUBSCRIPTION_ID}"'~' |
          sed 's~__SUBSCRIPTION_NAME__~'"${SP_SUBSCRIPTION_NAME}"'~' |
          sed 's~__SERVICE_CONNECTION_NAME__~'"${AZDO_SC_AZURERM_NAME}"'~' |
          sed 's~__PROJECT_ID__~'"${AZDO_PROJECT_ID}"'~' |
          #sed 's~__PROJECT_NAME__~'"${AZDO_PROJECT_NAME}"'~' |
          sed 's~__MANAGEMENT_URI__~'"${MANAGEMENT_URI}"'~'
      )
    fi
  else
    _template="$SCRIPT_DIR/templates/service-connection-create-server.json"
    _payload=$(
      cat "$_template" |
        sed 's~__SERVICE_PRINCIPAL_ID__~'"${SP_ID}"'~' |
        sed 's@__SERVICE_PRINCIPAL_KEY__@'"${SP_SECRET}"'@' |
        sed 's~__SERVICE_PRINCIPAL_TENANT_ID__~'"${SP_TENANT_ID}"'~' |
        sed 's~__CLOUD_ENVIRONMENT__~'"${SP_CLOUD_ENVIRONMENT}"'~' |
        sed 's~__SUBSCRIPTION_ID__~'"${SP_SUBSCRIPTION_ID}"'~' |
        sed 's~__SUBSCRIPTION_NAME__~'"${SP_SUBSCRIPTION_NAME}"'~' |
        sed 's~__SERVICE_CONNECTION_NAME__~'"${AZDO_SC_AZURERM_NAME}"'~' |
        sed 's~__MANAGEMENT_URI__~'"${MANAGEMENT_URI}"'~'
    )
  fi

  echo "$_payload"
}

function _get_management_endpoint() {
  local _response=$(az cloud show -n "${SP_CLOUD_ENVIRONMENT}")
  echo "$_response" >"$AZDO_TEMP_LOG_PATH/az-cloud-show-response.json"
  if [ "$INSTALL_TYPE" == "PAAS" ]; then
    MANAGEMENT_URI=$(echo "$_response" | jq .endpoints.management | sed "s/^\([\"']\)\(.*\)\1\$/\2/g")
  else
    MANAGEMENT_URI=$(echo "$_response" | jq .endpoints.resourceManager | sed "s/^\([\"']\)\(.*\)\1\$/\2/g")
  fi
  _debug "MANAGEMENT_URI: ${MANAGEMENT_URI}"

}

function _get_pipeline_var_defintion() {
  local _var_key=${1}
  local _var_value=${2}
  local _allowOverride=${3}
  local _template_file="$SCRIPT_DIR/templates/pipeline-variable.json"

  local _payload=$(
    sed <"${_template_file}" 's~__PIPELINE_VAR_NAME__~'"${_var_key}"'~' |
      sed 's~__PIPELINE_VAR_VALUE__~'"${_var_value}"'~' |
      sed 's~__PIPELINE_VAR_IS_SECRET__~'false'~' |
      sed 's~__PIPELINE_ALLOW_OVERRIDE__~'"${_allowOverride}"'~'
  )

  echo $_payload
}
function _get_agent_pool_queue() {
  # https://docs.microsoft.com/rest/api/azure/devops/distributedtask/queues/get%20agent%20queues?view=azure-devops-rest-5.1
  local _token=$(echo -n ":${AZDO_PAT}" | base64 -w 0)
  local _uri="${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/distributedtask/queues?api-version=5.1-preview.1"
  _response=$(request_get "$_uri" "application/json; charset=utf-8" "Basic ${_token}")
  _is_ubuntu=$(echo "$_response" | jq '.value[] | select( .name | contains("Ubuntu") )')

  if [ -z "${_is_ubuntu}" ]; then
    _default_pool=$(echo "$_response" | jq '.value[] | select( .name | contains("Default") )')
    agent_pool_queue_id=$(echo "$_default_pool" | jq -r '.id')
    agent_pool_queue_name=$(echo "$_default_pool" | jq -r '.name')
  else
    agent_pool_queue_id=$(echo "$_is_ubuntu" | jq -r '.id')
    agent_pool_queue_name=$(echo "$_is_ubuntu" | jq -r '.name')
  fi

  echo "{\"agent_pool_queue_id\":\"$agent_pool_queue_id\",\"agent_pool_queue_name\":\"$agent_pool_queue_name\"}"
}

function push_repo {
  local _token=$(echo -n ":${AZDO_PAT}" | base64 -w 0)
  git -c http.extraHeader="Authorization: Basic ${_token}" push -u origin --all
}

function configure_branches {
  _debug "skip configure branches"
}
