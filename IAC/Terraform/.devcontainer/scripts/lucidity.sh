#!/usr/bin/env bash
_error() {
    printf "\e[31mERROR: $@\n\e[0m"
}

_debug() {
    #Only print debug lines if debugging is turned on.
    if [ "$DEBUG_FLAG" == true ]; then
        msg="$@"
        LIGHT_CYAN='\033[0;35m'
        NC='\033[0m'
        printf "DEBUG: ${NC} %s ${NC}\n" "${msg}"
    fi
}

_debug_json() {
    if [ "$DEBUG_FLAG" == true ]; then
        echo $1 | jq
    fi
}

_information() {
    printf "\e[36m$@\n\e[0m"
}

_success() {
    printf "\e[32m$@\n\e[0m"
}

declare COMMAND=
declare FLAGS=""
declare md5=$(printf '%s' "/home/vscode/repos/Terraform-Code" | md5sum | awk '{print $1}')
declare TMP_ENV_PATH=~/.lucidity/tmp/$md5
declare SP_SUBSCRIPTION_NAME=''
declare SP_ID=''
declare SP_SUBSCRIPTION_ID=''
declare SP_SECRET=''
declare SP_TENANT_ID=''
declare STORAGE_ACCOUNT_NAME=''

# Initialize parameters specified from command line
while (( "$#" )); do
    case "${1}" in
        login)
            shift 1
            COMMAND="login"
            ;;
        env)
            shift 1
            COMMAND="env"
            ;;   
        state)
            shift 1
            COMMAND="state"
            ;;     
        version)
            shift 1
            COMMAND="version"
            ;;
        help)
            shift 1
            COMMAND="help"            
            ;;                           
        *) # preserve positional arguments
            FLAGS+="${1} "
            shift
            ;;
        esac
done
FLAGS=$(echo $FLAGS | sed -e 's/^[ \t]*//')\

print_banner() {
  local version=$1
  cat << "EOF"

 ██╗     ██╗   ██╗ ██████╗██╗██████╗ ██╗████████╗██╗   ██╗
 ██║     ██║   ██║██╔════╝██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝
 ██║     ██║   ██║██║     ██║██║  ██║██║   ██║    ╚████╔╝ 
 ██║     ██║   ██║██║     ██║██║  ██║██║   ██║     ╚██╔╝  
 ███████╗╚██████╔╝╚██████╗██║██████╔╝██║   ██║      ██║   
 ╚══════╝ ╚═════╝  ╚═════╝╚═╝╚═════╝ ╚═╝   ╚═╝      ╚═╝                                                            

EOF

  echo " version: $(cat /home/vscode/.lucidity/version.txt)"
  echo ""                                                         
  echo " Project Lucidity allows you to easily deploy infrastructure to Azure  using Terraform.  "                                                         
  echo ""                                                         
}

usage() {
  print_banner
  _helpText=" Usage: lucidity <command> <action> <flags>
  commands:
     env: 
        Allows you reload environment variables or view the current loaded .env file.
        - lucidity env reload
        - lucidity env show
        - lucidity env (defaults to show)

     login:
        Allows loggin in via an Azure user or Service principal. 
        Login performs an az login and sets up ARM environment variables if using an service principal.
        - lucidity login
        - lucidity login -s \"<SP STRING>\"
        - lucidity login -h

     state:
        Configures terraform remote state.
        - lucidity state set -remote

     version:
        Prints the current lucidity cli version.
"      
        _information "$_helpText" 1>&2
        exit 0  
}

create_arm_tfvars() {
    local armFile="$TMP_ENV_PATH/environments/dev/arm.env"
    echo "ARM_SUBSCRIPTION_ID=$SP_SUBSCRIPTION_ID" > $armFile
    echo "ARM_TENANT_ID=$SP_TENANT_ID"  >> $armFile
    echo "ARM_CLIENT_ID=$SP_ID" >> $armFile
    echo "ARM_CLIENT_SECRET=$SP_SECRET" >> $armFile   
    _success "Sucessfully added ARM ENV VARS to $armFile"
}

split_equals() {
  BFS=$IFS
  IFS='='
  read -ra arr <<<"$1"
  IFS=$BFS
  echo ${arr[1]}  
}

dir_env_reload() {
  pushd /home/vscode/repos/Terraform-Code
    direnv reload
  popd
}

process_login() {
  local spLogin=false
  while [[ $# -gt 0 ]]
  do
    case $1 in
      *SP_SUBSCRIPTION_ID*)
        SP_SUBSCRIPTION_ID=$(split_equals $1)      
      ;;
      *SP_ID*)
        SP_ID=$(split_equals $1) 
      ;;  
      *SP_SECRET*)
        SP_SECRET=$(split_equals $1)    
      ;;
      *SP_TENANT_ID*)
        SP_TENANT_ID=$(split_equals $1)    
      ;;      
      -h | --help )  
        print_banner
        _helpText=" Usage: lucidity login <-s>    
  Lucidity allows you to login as either a user or a service principle. This is used for terraform plan and apply.

  * Option 1 - User Login: 'lucidity login'
    This performs an az login and starts the device login workflow.

  * Option 2 - Service Principle login 'lucidity login -s'
    Login with a service principal. Configures the environment variables needed for terraform to use this SP.

    -s | --servicePrincipal <SP_INFORMATION> 
            Expected Format:
            SP_ID=<Service Principal ID> SP_SUBSCRIPTION_ID=<Azure Subscription ID> SP_SECRET=<Service Principal Secret> SP_TENANT_ID=<Service Principal Tenant ID>

       "      
        _information "$_helpText" 1>&2
        exit 0
      ;;   
      *)
        spLogin=true  
      ;;             
    esac
    shift
  done
  if [ $spLogin == "true" ]; then
    create_arm_tfvars
    dir_env_reload
    _information "Logging in to az cli as client id $SP_ID"
    az login --service-principal --username $SP_ID --password $SP_SECRET --tenant $SP_TENANT_ID
  else
    az login
  fi
}

create_backend_tfvars() {
    local backendFile="$TMP_ENV_PATH/environments/dev/backend.tfvars"
    touch $backendFile
    echo "storage_account_name  = \"${TF_VAR_BACKEND_STORAGE_ACCOUNT_NAME}\"" > $backendFile
    echo "container_name        = \"tfrs\"" >> $backendFile
    echo "resource_group_name   = \"tf-remote-state-dev\"" >> $backendFile
    echo "subscription_id   = \"$ARM_SUBSCRIPTION_ID\"" >> $backendFile
    echo "tenant_id         = \"$ARM_TENANT_ID\""  >> $backendFile
    echo "client_id         = \"$ARM_CLIENT_ID\"" >> $backendFile
    echo "client_secret     = \"$ARM_CLIENT_SECRET\"" >> $backendFile
   _success "Sucessfully created backend.tfvars in $backendFile"
}


remove_override_tf() {
    local DEPLOYMENTS
    pushd ~/repos/Terraform-Code/terraform
        DEPLOYMENTS=`find . -type d | grep '.\/[0-9][0-9]' | cut -c 3- | grep -v '^01_init' | grep -v '.*\/modules\/.*' | grep -v '.*\/modules' | grep -v '.*\.terraform' | grep '.*\/.*' | sort`
        DEPLOYMENTS=`echo $DEPLOYMENTS | sed 's/\.\///' | sed 's/^//;s/$/,/' | sed '$ s/.$//'`
        for deployment in $DEPLOYMENTS; do
            pushd $deployment > /dev/null
                if [ -f "_override.tf" ]; then
                    rm _override.tf 
                fi
                cp /home/vscode/.lucidity/.envcrc-tf-remote-state ./.envrc >/dev/null
                direnv allow
            popd

        done    
    popd
}

process_state() {
  local flags=$1
  local isRemote=false
  while [[ $# -gt 0 ]]
  do
    case $1 in
      -remote)
        isRemote=true    
      ;;
      -h | --help )  
        print_banner
        _helpText=" Usage: lucidity state set <-s> "
        _information "$_helpText" 1>&2
        exit 0
      ;;   
      *)
        spLogin=true  
      ;;             
    esac
    shift
  done
  if [ $isRemote == "true" ]; then
    pushd $TMP_ENV_PATH
      set -o allexport && . dev.compiled.env  && set +o allexport
      create_backend_tfvars
      remove_override_tf
    popd
  # else
  #   # todo support downgrading to local state from remote
  fi
}
function process_actions {
    case "${COMMAND}" in
        env)
            if [ "$FLAGS" = "reload" ]; then
              dir_env_reload
            else
              echo "Current environment variables loaded from file: $TMP_ENV_PATH/dev.compiled.env"
            fi              
            exit 0
            ;;
        login)
            process_login $FLAGS
            exit 0
            ;;        
        state)
            process_state $FLAGS
            exit 0
            ;;    
        version)
            cat /home/vscode/.lucidity/version.txt
            exit 0
            ;;
        help)
            usage
            exit 0
            ;;
        launchpad|landingzone)
            verify_parameters
            deploy ${TF_VAR_workspace}
            ;;
        *)
            usage
    esac
}

process_actions




