#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR"/../../../utilities/shell_logger.sh
source "$SCRIPT_DIR"/../../../utilities/shell_inputs.sh
source "$SCRIPT_DIR"/../../../utilities/http.sh

########################################################################################
#
# Configure GitHub Repo for Symphony
#
########################################################################################

function load_inputs {
  $(gh version >/dev/null 2>&1)
  code=$?
  if [ "$code" == "127" ]; then
    _error "github cli is not installed! Please install the gh cli https://cli.github.com/"
    exit 1
  fi

  _information "Load GitHub Configurations"

  if [ -z "$GH_ORG_NAME" ]; then
    _prompt_input "Enter existing GitHub Org Name" GH_ORG_NAME
  fi

  if [ -z "$GH_Repo_NAME" ]; then
    _prompt_input "Enter the name of a new GitHub Repo to be created" GH_Repo_NAME
  fi

  if [ -z "$IS_Private_GH_Repo" ]; then
    _select_yes_no IS_Private_GH_Repo "Is GitHub Repo Private (yes/no)" "false"
  fi

  $(gh auth status >/dev/null 2>&1)
  code=$?
  if [ "$code" == "0" ]; then
    _information "GitHub Cli is already logged in. Bootstrap with existing authorization."
  else
    local login_to_github
    _select_yes_no login_to_github "Do an interactive login to the gh cli" "true"
    if [ "$login_to_github" == "true" ]; then
      gh auth login
    else
      if [ -z "$GH_PAT" ]; then
        _prompt_input "Enter GitHub PAT" GH_PAT
      fi
      echo "$GH_PAT" | gh auth login --with-token
    fi
  fi
}

function configure_repo {
  _information "Starting project creation for project ${GH_Repo_NAME}"

  visibility="--public"
  if [ "$IS_Private_GH_Repo" == "yes" ]; then
    visibility="--private"
  fi

  git init
  git branch -m main

  command="gh repo create $GH_ORG_NAME/$GH_Repo_NAME $visibility --source=."
  _information "running - $command"
  eval "$command"

  # GET Repos Git Url and Repo Id's
  response=$(gh repo view "$GH_ORG_NAME/$GH_Repo_NAME" --json sshUrl,url,id)
  CODE_REPO_GIT_HTTP_URL=$(echo "$response" | jq -r '.url')
  CODE_REPO_ID=$(echo "$response" | jq -r '.id')
  _debug "$CODE_REPO_GIT_HTTP_URL"
  _debug "$CODE_REPO_ID"

  _success "Repo '${GH_Repo_NAME}' created."
}

function configure_runners {
  # Replace in all files in ./.github/workflows "runs-on: ubuntu-latest" with "runs-on: self-hosted"
  if [[ "$OSTYPE" == "darwin"* ]]; then
      for file in ./.github/workflows/*; do
          sed -i '' -E 's/([[:space:]]*)runs-on: ubuntu-latest([[:space:]]*)/\1runs-on: self-hosted\2/g' "$file"
      done
  else
      for file in ./.github/workflows/*; do
          sed -i -E 's/([[:space:]]*)runs-on: ubuntu-latest([[:space:]]*)/\1runs-on: self-hosted\2/g' "$file"
      done
  fi

  # Verify that required variables exist
  local REQUIRED_VARS=(\
      GH_ORG_NAME \
      GH_Repo_NAME \
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

  # Optional parameter: VM name (default: symphony-github-runner)
  RUNNERS_VM_NAME=${RUNNERS_VM_NAME:-symphony-github-runner}-${GH_Repo_NAME}

  # Optional parameter: VM username (default: azureuser)
  RUNNERS_VM_USERNAME=${RUNNERS_VM_USERNAME:-azureuser}

  # Retrieve multiple GitHub runner registration tokens
  _information "Retrieving ${RUNNERS_COUNT} GitHub runner registration tokens..."
  local tokens=()

  for i in $(seq 1 "$RUNNERS_COUNT"); do
      local token=$(gh api -X POST /repos/${GH_ORG_NAME}/${GH_Repo_NAME}/actions/runners/registration-token -q .token)

      if [[ "$token" == "null" || -z "$token" ]]; then
          _error "Error: Failed to retrieve token for runner $i."
          exit 1
      fi

      tokens+=("$token")

      _information "Sleeping for 1 second to avoid repeated token requests..."
      sleep 1
  done

  _information "All tokens retrieved successfully."

  # Convert tokens array into a space-separated string
  local token_string=$(IFS=" " ; echo "${tokens[*]}")

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
    - path: /runner-install.sh
      permissions: '0777'
      content: |
          #!/usr/bin/env bash

          cd /home/$RUNNERS_VM_USERNAME

          # Enable Docker
          sudo systemctl enable --now docker
          sudo usermod -aG docker $RUNNERS_VM_USERNAME

          # Install GitHub runner

          # Tokens from cloud-init
          TOKENS=(${token_string})

          for i in \$(seq 1 ${RUNNERS_COUNT}); do
              RUNNER_DIR="/home/$RUNNERS_VM_USERNAME/github-runner-\$i"
              echo "Configuring runner in \$RUNNER_DIR..."
              mkdir -p "\$RUNNER_DIR"
              cd "\$RUNNER_DIR"

              # Download a fixed version of the runner
              RUNNER_VERSION="2.322.0"
              curl -O -L "https://github.com/actions/runner/releases/download/v\${RUNNER_VERSION}/actions-runner-linux-x64-\${RUNNER_VERSION}.tar.gz"
              tar xzf "actions-runner-linux-x64-\${RUNNER_VERSION}.tar.gz"

              # Configure the runner non-interactively using its respective token
              ./config.sh --url "https://github.com/${GH_ORG_NAME}/${GH_Repo_NAME}" --token "\${TOKENS[\$((i-1))]}" --unattended --name "runner-\$i"

              # Install the service
              sudo ./svc.sh install

              # Start the runner in the background
              sudo ./svc.sh start

              # Return to the home directory for the next iteration
              cd /home/$RUNNERS_VM_USERNAME
          done
  runcmd:
    - sudo -u $RUNNERS_VM_USERNAME /runner-install.sh
EOF

  _information "cloud-init.yaml file generated."

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

function _add_federated_credential {
  # Configuring federated identity for Github Actions, based on repo name and environment name
  parameters=$(cat <<EOF
  {
    "name": "symphony-credential-${GH_ORG_NAME}-${GH_Repo_NAME}",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:${GH_ORG_NAME}/${GH_Repo_NAME}:environment:symphony",
    "description": "Symphony credential for Github Actions",
    "audiences": [
        "api://AzureADTokenExchange"
    ]
  }
EOF
  )

  az ad app federated-credential create --id $SP_ID --parameters "$parameters"
}

function configure_credentials {
  _information "Configure GitHub Secrets"

  _add_federated_credential

  gh secret set "AZURE_SUBSCRIPTION_ID" --repo "${GH_ORG_NAME}/${GH_Repo_NAME}" --body "$SP_SUBSCRIPTION_ID"
  gh secret set "AZURE_TENANT_ID" --repo "${GH_ORG_NAME}/${GH_Repo_NAME}" --body "$SP_TENANT_ID"
  gh secret set "AZURE_CLIENT_ID" --repo "${GH_ORG_NAME}/${GH_Repo_NAME}" --body "$SP_ID"
  gh variable set EVENTS_STORAGE_ACCOUNT --repo "${GH_ORG_NAME}/${GH_Repo_NAME}" --body "$SYMPHONY_EVENTS_STORAGE_ACCOUNT"
  gh variable set EVENTS_TABLE_NAME --repo "${GH_ORG_NAME}/${GH_Repo_NAME}" --body "$SYMPHONY_EVENTS_TABLE_NAME"


}

function create_pipelines_bicep {
  _debug "skip create_pipelines_bicep"
}

function create_pipelines_terraform {
  gh variable set STATE_RG --repo "${GH_ORG_NAME}/${GH_Repo_NAME}" --body "$SYMPHONY_RG_NAME"
  gh variable set STATE_STORAGE_ACCOUNT --repo "${GH_ORG_NAME}/${GH_Repo_NAME}" --body "$SYMPHONY_SA_STATE_NAME"
  gh variable set STATE_STORAGE_ACCOUNT_BACKUP --repo "${GH_ORG_NAME}/${GH_Repo_NAME}" --body "$SYMPHONY_SA_STATE_NAME_BACKUP"
  gh variable set STATE_CONTAINER --repo "${GH_ORG_NAME}/${GH_Repo_NAME}" --body "$SYMPHONY_STATE_CONTAINER"
}

function push_repo {
  git push origin --all
}

function configure_branches {
  # Enable Branch Protection rules
  command="gh api --silent -X PUT /repos/$GH_ORG_NAME/$GH_Repo_NAME/branches/main/protection \
        --input - << EOF
        {
            \"required_status_checks\": {
                \"strict\":true,
                \"contexts\":[
                    \"Test / Test\"
                ]
            },
            \"required_pull_request_reviews\": {
                \"dismiss_stale_reviews\":false,
                \"require_code_owner_reviews\":false,
                \"require_last_push_approval\":false,
                \"required_approving_review_count\":1
            },
            \"enforce_admins\":false,
            \"restrictions\": null
        }
EOF"
  echo "running - $command"
  eval "$command"
}
