#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "$SCRIPT_DIR"/../../../utilities/shell_logger.sh
source "$SCRIPT_DIR"/../../../utilities/shell_inputs.sh
source "$SCRIPT_DIR"/../../../utilities/http.sh

########################################################################################
#
# Configure GitHub Repo for Symphony
#
########################################################################################

function load_inputs {
    $(gh version>/dev/null 2>&1)
    code=$?
    if [ "$code" == "127" ]; then
        _error "github cli is not installed! Please install the gh cli https://cli.github.com/"
        exit 1
    fi

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

    $(gh auth status>/dev/null 2>&1)
    code=$?
    if [ "$code" == "0" ]; then
        _information "GitHub Cli is already logged in. Bootstrap with existing authorization."
    else
        if [ -z "$GH_PAT" ]; then
            _prompt_input "Enter GitHub PAT" GH_PAT
        fi
         echo "$GH_PAT" | gh auth login --with-token
    fi
}

function configure_repo { 
    _information "Starting project creation for project ${GH_Repo_NAME}"

    visibility="--public"
    if [ "$IS_Private_GH_Repo" == "true" ]; then
      visibility="--private"
    fi

    command="gh repo create $GH_ORG_NAME/$GH_Repo_NAME $visibility"
    _information "running - $command"
    eval "$command" 
         
    # 2. GET Repos Git Url and Repo Id's
    response=$(gh repo view "$GH_ORG_NAME/$GH_Repo_NAME" --json sshUrl,url,id)
    CODE_REPO_GIT_HTTP_URL=$(echo "$response" | jq -r '.url')
    CODE_REPO_ID=$(echo "$response" | jq -r '.id')
    _debug "$CODE_REPO_GIT_HTTP_URL"
    _debug "$CODE_REPO_ID"

    # Configure remote for local git repo
    remoteWithCreds="https://${GH_PAT}@github.com/${GH_ORG_NAME}/${GH_Repo_NAME}.git"
    git init
    git branch -m main
    git remote add origin "$remoteWithCreds"

    _success "Repo '${GH_Repo_NAME}' created."
}

function _build_az_secret {
    echo "{\"clientId\": \"$SP_ID\",\"clientSecret\": \"$SP_SECRET\",\"subscriptionId\": \"$SP_SUBSCRIPTION_ID\",\"tenantId\": \"$SP_TENANT_ID\"}"
}

function configure_credentials {
    _information "Configure Github Secrets"

    sp_json=$(_build_az_secret)
    gh secret set "AZURE_CREDENTIALS" --repo "${GH_ORG_NAME}/${GH_Repo_NAME}" --body "$sp_json"
}

function create_pipelines_bicep {
    _debug "skip create_pipelines_bicep"
}

function create_pipelines_terraform {
    _debug "skip create_pipelines_terraform"
}