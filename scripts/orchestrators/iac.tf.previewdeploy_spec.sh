#######################################################################################################
# This is a BDD unit test file and can be invoked using ShellSpec - https://github.com/shellspec/shellspec
# This Spec File combination of ShellSpec DLS and Bash
#######################################################################################################
Describe 'iac.tf.validate.sh'
  setup_root(){
      pushd ../../
        export ROOT_WORKSPACE_PATH=$(pwd)
      popd
      export RUN_ID=1
      export ENVIRONMENT_NAME="dev"
      export LOCATION_NAME="westus"
      export STATE_STORAGE_ACCOUNT="sastatedngwzqxq134" 
      export STATE_CONTAINER="tfstate" 
      export STATE_RG="rg-dngwzqxq-134"
      export IS_TEST=1
      # Get ARM variables from test_auth file
      # The .symphony folder is in the .gitignore to ensure the auth credentials are not checked in.
      source ../../.symphony/test_auth.sh
  }

  # mocks
  azlogin(){
    echo "AZ LOGIN"
  }

  init(){
    backend_config=$1
    key=$2
    subscription_id=$3
    tenant_id=$4
    client_id=$5
    client_secret=$6
    storage_account_name=$7
    container_name=$8
    resource_group_name=$9
        
    echo "TF INIT Key=$key"
  }

  preview() {
    plan_file_name=$1
    var_file=$2
    echo "TF PREVIEW - plan_file:$plan_file_name var_file:$var_file"
  }

  detect_destroy(){
    plan_file_name=$1
    echo "DETECT DESTROY - plan_file_name:$plan_file_name"
  }

  deploy(){
    plan_file_name=$1
    echo "DEPLOY - plan_file_name:$plan_file_name"
  }




  Context "IAC Folder"
    setup(){
      setup_root
      export WORKSPACE_PATH="$ROOT_WORKSPACE_PATH"
      export RUN_ID=2
    }
    BeforeEach 'setup'

    It 'should call the tf init method with the correct values'
      When run source "iac.tf.previewdeploy.sh"
      The output should include "TF INIT Key=dev./02_sql/01_deployment.tfstate"
      The output should include "TF INIT Key=dev./03_webapp/01_deployment"
    End

    It 'should call the tf plan method with the correct value'
      When run source "iac.tf.previewdeploy.sh"
      The output should include "TF PREVIEW - plan_file:terraform.tfplan var_file:$WORKSPACE_PATH/env/terraform/dev/03_webapp_01_deployment.tfvars.json"
      The output should include "TF PREVIEW - plan_file:terraform.tfplan var_file:$WORKSPACE_PATH/env/terraform/dev/03_webapp_01_deployment.tfvars.json"
    End


    It 'should call the detect_destroy method with the correct value'
      When run source "iac.tf.previewdeploy.sh"
      The output should include "DETECT DESTROY - plan_file_name:terraform.tfplan"
    End    

    It 'should call the tf deploy method with the correct value'
      When run source "iac.tf.previewdeploy.sh"
      The output should include "DEPLOY - plan_file_name:terraform.tfplan"
    End        
  End
      
End 
