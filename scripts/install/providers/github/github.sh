#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source $SCRIPT_DIR/../../../utilities/shell_logger.sh
source $SCRIPT_DIR/../../../utilities/shell_inputs.sh
source $SCRIPT_DIR/../../../utilities/http.sh

########################################################################################
#
# Configure GitHub Repo for Symphony
#
########################################################################################

function load_inputs {
    _information "Load GitHub Configurations"
  
    if [ -z "$GH_ORG_NAME" ]; then
        _prompt_input "Enter GitHub Org Name" GH_ORG_NAME
    fi

    if [ -z "$GH_Repo_NAME" ]; then
        _prompt_input "Enter GitHub Repo Name" GH_Repo_NAME
    fi

    if [ -z "$IS_Private_GH_Repo" ]; then
        _prompt_input "IS GitHub Repo Private [true;false]" IS_Private_GH_Repo
    fi

    if [ -z "$GH_PAT" ]; then
        _prompt_input "Enter GitHub PAT" GH_PAT
    fi

}


function configure_repo { 
    _information "Starting project creation for project ${GH_Repo_NAME}"

    # 1. Create repo request
    # GH API Service     : https://docs.github.com/en/rest/repos/repos#create-an-organization-repository
    # POST               : https://api.github.com/orgs/{org}/repos
    _payload=$(cat "$SCRIPT_DIR/templates/repo-create.json" | sed 's~__GH_REPO_NAME__~'"${GH_Repo_NAME}"'~' | sed 's~__PRIVATE_GH_REPO__~'"$IS_Private_GH_Repo"'~' )
    _uri="https://api.github.com/orgs/${GH_ORG_NAME}/repos"

    _debug "Creating project"
    
    # 2. POST Create repo request
    _response=$( request_post \
                   "${_uri}" \
                   "${_payload}" \
                   "application/vnd.github+json" \
                   "Bearer ${GH_PAT}"
               )


    echo $_response > $SCRIPT_DIR/temp/${GH_Repo_NAME}-cp.json 
    local _createProjectMsg=$(echo $_response | jq -r '.message')
    if [ "$_createProjectMsg" = "Repository creation failed." ]; then
        echo "Repository creation failed."
        _errorMsg=$(echo $_response | jq -r '.errors[].message')
        _error "Error creating project in org '${_errorMsg}'. \n "
        exit 1
    fi
    
    _debug_log_post "$_uri" "$_response" "$_payload"
    sleep 2

         
    # 2. GET Repos Git Url and Repo Id's
    CODE_REPO_GIT_HTTP_URL=$(cat $SCRIPT_DIR/temp/${GH_Repo_NAME}-cp.json | jq -r '.git_url')
    CODE_REPO_ID=$(cat $SCRIPT_DIR/temp/${GH_Repo_NAME}-cp.json | jq -r '.id')
    _debug "$CODE_REPO_GIT_HTTP_URL"
    _debug "$CODE_REPO_ID"

    # Configure remote for local git repo
    remoteWithCreds="https://${GH_PAT}@github.com/${GH_ORG_NAME}/${GH_Repo_NAME}.git"
    git remote set-url origin $remoteWithCreds

    _success "Repo '${GH_Repo_NAME}' created."
}

function configure_credentials {
    _information "Configure Github Secrets"

    # 0- Build the secret content from the SP variables.
    # 1- Get a repository public key
    # 2- Download libsodium exe
    # 3- Encript the secret
    # 4- post the secret.

}

function _build_az_secret {

    # {
    # "clientId": "<GUID>",
    # "clientSecret": "<GUID>",
    # "subscriptionId": "<GUID>",
    # "tenantId": "<GUID>",
    # (...)}

}