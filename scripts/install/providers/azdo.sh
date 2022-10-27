#!/usr/bin/env bash

source ./../../utilities/shell_logger.sh

########################################################################################
#
# Configure Azure DevOps Project for Symphony
#
########################################################################################

function create_pipeline {
    echo "Create Pipeline AzDo"
}

function create_project {
    echo "Create Project AzDo"

    _information "Starting project creation for project ${AZDO_PROJECT_NAME}"

    # Refactor
    # 1. GET Get all processes to get template id
    # AzDo Service     : Processes - Get https://docs.microsoft.com/rest/api/azure/devops/core/processes/get?view=azure-devops-rest-5.1
    # AzDo Server 2019 : Processes - Get https://docs.microsoft.com/rest/api/azure/devops/core/processes/get?view=azure-devops-server-rest-5.0
    # GET https://{instance}/{collection}/_apis/process/processes/{processId}?api-version=5.0
    _uri=$(_set_api_version "${AZDO_ORG_URI}/_apis/process/processes?api-version=" '5.1' '5.1')
    
    _debug "Requesting process templates"

    _response=$(request_get "${_uri}")
    echo $_response > ./temp/pt.json
    
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
    _processTemplateId=$(cat ./temp/pt.json | jq -r '.value[] | select(.name == "'"${AZDO_PROJECT_PROCESS_TEMPLATE}"'") | .id')

    # 2. Create Project
    # AzDo Service     : Projects - Create https://docs.microsoft.com/rest/api/azure/devops/core/projects/create?view=azure-devops-rest-5.1
    # AzDo Server 2019 : Projects - Create https://docs.microsoft.com/rest/api/azure/devops/core/projects/create?view=azure-devops-server-rest-5.0
    # POST https://{{coreServer}}/{{organization}}/_apis/projects?api-version={{api-version}}
    _payload=$(cat "payloads/template.project-create.json" | sed 's~__AZDO_PROJECT_NAME__~'"${AZDO_PROJECT_NAME}"'~' | sed 's~__AZDO_PROJECT_SOURCE_CONTROL__~'"${AZDO_PROJECT_SOURCE_CONTROL}"'~' | sed 's~__AZDO_PROCESS_TEMPLATE_ID__~'"${_processTemplateId}"'~')
    _uri=$(_set_api_version "${AZDO_ORG_URI}/_apis/projects?api-version=" '5.1' '5.1')

    _debug "Creating project"
    # 2. POST Create project
    _response=$( request_post \
                   "${_uri}" \
                   "${_payload}" 
               )
    echo $_response > ./temp/cp.json    
    local _createProjectTypeKey=$(echo $_response | jq -r '.typeKey')
    if [ "$_createProjectTypeKey" = "ProjectAlreadyExistsException" ]; then
        _error "Error creating project in org '${AZDO_ORG_URI}. \nProject repo '${AZDO_PROJECT_NAME}' already exists."
        exit 1
    fi
    
    _debug_log_post "$_uri" "$_response" "$_payload"

    #When going through rest apis, there is a timing issue from project create to querying the repo properties.
    sleep 10s

    # Fetch The list of projects to get this project's id
    # https://docs.microsoft.com/rest/api/azure/devops/core/Projects/List?view=azure-devops-server-rest-5.0
    # GET https://{instance}/{collection}/_apis/projects?api-version=5.0
    _uri="${AZDO_ORG_URI}/_apis/projects?api-version=5.0"
    _response=$(request_get $_uri)
    echo $_response > './temp/get-project-id.json'
    AZDO_PROJECT_ID=$(cat './temp/get-project-id.json' | jq -r '.value[] | select (.name == "'"${AZDO_PROJECT_NAME}"'") | .id')
    
    # 3. Create Repos
    #https://docs.microsoft.com/rest/api/azure/devops/git/repositories/create?view=azure-devops-rest-5.1
    _information "Creating ${PIPELINE_REPO_NAME} Repository"
    _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/git/repositories/${AZDO_PROJECT_NAME}?api-version=" '5.1' '5.1')
    _payload=$(cat "payloads/template.repo-create.json" | sed 's~__AZDO_PROJECT_ID__~'"${AZDO_PROJECT_ID}"'~' | sed 's~__REPO_NAME__~'"${PIPELINE_REPO_NAME}"'~' )
    _response=$(request_post "${_uri}" "${_payload}") 
    echo $_response > "./temp/$PIPELINE_REPO_NAME-create-response.json"

    _information "Creating ${CODE_REPO_NAME} Repository"
    _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/git/repositories/${AZDO_PROJECT_NAME}?api-version=" '5.1' '5.1')
    _payload=$(cat "payloads/template.repo-create.json" | sed 's~__AZDO_PROJECT_ID__~'"${AZDO_PROJECT_ID}"'~' | sed 's~__REPO_NAME__~'"${CODE_REPO_NAME}"'~' )
    _response=$(request_post "${_uri}" "${_payload}") 
    echo $_response > "./temp/$CODE_REPO_NAME-create-response.json"    

    _information "Creating ${ENV_REPO_NAME} Repository"
    _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/git/repositories/${AZDO_PROJECT_NAME}?api-version=" '5.1' '5.1')
    _payload=$(cat "payloads/template.repo-create.json" | sed 's~__AZDO_PROJECT_ID__~'"${AZDO_PROJECT_ID}"'~' | sed 's~__REPO_NAME__~'"${ENV_REPO_NAME}"'~' )
    _response=$(request_post "${_uri}" "${_payload}") 
    echo $_response > "./temp/$ENV_REPO_NAME-create-response.json"    

    # 4. GET Repos Git Url and Repo Id's
    # AzDo Service     : Repositories - Get Repository https://docs.microsoft.com/rest/api/azure/devops/git/repositories/get%20repository?view=azure-devops-rest-5.1
    # AzDo Server 2019 : Repositories - Get Repository https://docs.microsoft.com/rest/api/azure/devops/git/repositories/get%20repository?view=azure-devops-server-rest-5.0
    # GET https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}?api-version=5.1
    _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/git/repositories/${PIPELINE_REPO_NAME}?api-version=" '5.1' '5.1')
    _debug "Fetching ${PIPELINE_REPO_NAME} repository information"
    
    _response=$( request_get ${_uri}) 
    _debug_log_get "$_uri" "$_response"
    
    echo $_response > "./temp/${PIPELINE_REPO_NAME}-ri.json"
    PIPELINE_REPO_GIT_HTTP_URL=$(cat "./temp/${PIPELINE_REPO_NAME}-ri.json" | jq -c -r '.remoteUrl')
    PIPELINE_REPO_ID=$(cat "./temp/${PIPELINE_REPO_NAME}-ri.json" | jq -c -r '.id')
    _debug "$PIPELINE_REPO_GIT_HTTP_URL"

    echo "${PIPELINE_REPO_NAME} Git Repo remote URL: "$PIPELINE_REPO_GIT_HTTP_URL

    _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/git/repositories/${CODE_REPO_NAME}?api-version=" '5.1' '5.1')
    _debug "Fetching ${CODE_REPO_NAME} repository information"
    _response=$( request_get ${_uri}) 
    _debug_log_get "$_uri" "$_response"

    echo $_response > "./temp/${CODE_REPO_NAME}-ri.json"
    CODE_REPO_GIT_HTTP_URL=$(cat "./temp/${CODE_REPO_NAME}-ri.json" | jq -c -r '.remoteUrl')
    CODE_REPO_ID=$(cat "./temp/${CODE_REPO_NAME}-ri.json" | jq -c -r '.id')
    _debug "$CODE_REPO_GIT_HTTP_URL"
    echo "${CODE_REPO_NAME} Git Repo remote URL: "$CODE_REPO_GIT_HTTP_URL

    _uri=$(_set_api_version "${AZDO_ORG_URI}/${AZDO_PROJECT_NAME}/_apis/git/repositories/${ENV_REPO_NAME}?api-version=" '5.1' '5.1')
    _debug "Fetching ${ENV_REPO_NAME} repository information"
    _response=$( request_get ${_uri}) 
    _debug_log_get "$_uri" "$_response"

    echo $_response > "./temp/${ENV_REPO_NAME}-ri.json"
    ENV_REPO_GIT_HTTP_URL=$(cat "./temp/${ENV_REPO_NAME}-ri.json" | jq -c -r '.remoteUrl')
    ENV_REPO_ID=$(cat "./temp/${ENV_REPO_NAME}-ri.json" | jq -c -r '.id')
    _debug "$ENV_REPO_GIT_HTTP_URL"
    echo "${CODE_REPO_NAME} Git Repo remote URL: "$ENV_REPO_GIT_HTTP_URL

    _information "Project '${AZDO_PROJECT_NAME}' created."
}