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
    _prompt_input "Enter Azure Devops PAT" AZDO_PAT
  fi
}

function configure_repo {
  _information "Create Project AzDo"

  local project_source_control='git'
  local project_process_tempalte='Agile'
  local _token=$(echo -n ":${AZDO_PAT}" | base64)

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

function configure_credentials {
  _information "Configure Service Connections"
  _create_arm_svc_connection
}

function create_pipelines_terraform() {
  _information "Creating Azure Pipelines "
  local pipelineVariables

  pipelineVariables=$(_get_pipeline_var_defintion environmentName dev true)
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion keyVaultArmSvcConnectionName Symphony-KV true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion keyVaultName ${SYMPHONY_KV_NAME} true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion goVersion 1.18.1 true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion terraformVersion 1.6.2 true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion runLayerTest false true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion runBackupState true true)"
  _create_pipeline "CI-Deploy" "/.azure-pipelines/pipeline.ci.terraform.yml" "Deploy" "${pipelineVariables}" "${AZDO_PROJECT_NAME}"

  pipelineVariables=$(_get_pipeline_var_defintion environmentName dev true)
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion keyVaultArmSvcConnectionName Symphony-KV true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion keyVaultName ${SYMPHONY_KV_NAME} true)"
  _create_pipeline "Destroy" "/.azure-pipelines/pipeline.destroy.terraform.yml" "Destroy" "${pipelineVariables}" "${AZDO_PROJECT_NAME}"

}

function create_pipelines_bicep() {
  _information "Creating Azure Pipelines "
  local pipelineVariables

  pipelineVariables=$(_get_pipeline_var_defintion environmentName dev true)
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion locationName westus true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion keyVaultArmSvcConnectionName Symphony-KV true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion keyVaultName ${SYMPHONY_KV_NAME} true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion excludedFolders , true)"
  _create_pipeline "CI-Deploy" "/.azure-pipelines/pipeline.ci.bicep.yml" "Deploy" "${pipelineVariables}" "${AZDO_PROJECT_NAME}"

  pipelineVariables=$(_get_pipeline_var_defintion environmentName dev true)
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion locationName westus true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion keyVaultArmSvcConnectionName Symphony-KV true)"
  pipelineVariables="$pipelineVariables, $(_get_pipeline_var_defintion keyVaultName ${SYMPHONY_KV_NAME} true)"
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

  local _token=$(echo -n ":${AZDO_PAT}" | base64)
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
  local _token=$(echo -n ":${AZDO_PAT}" | base64)

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
  local _token=$(echo -n ":${AZDO_PAT}" | base64)
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

  local AZDO_SC_AZURERM_NAME='Symphony-KV'

  if [ "$INSTALL_TYPE" == "PAAS" ]; then
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
  local _token=$(echo -n ":${AZDO_PAT}" | base64)
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
  local _token=$(echo -n ":${AZDO_PAT}" | base64)
  git -c http.extraHeader="Authorization: Basic ${_token}" push -u origin --all
}

function configure_branches {
  _debug "skip configure branches"
}
