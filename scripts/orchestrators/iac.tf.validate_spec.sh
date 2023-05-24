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
      # Get ARM variables from test_auth file
      # The .symphony folder is in the .gitignore to ensure the auth credentials are not checked in.
      source ../../.symphony/test_auth.sh
  }

  Context "IAC Folder"
    setup(){
      setup_root
      export WORKSPACE_PATH="$ROOT_WORKSPACE_PATH"
      export RUN_ID=2
    }
    BeforeEach 'setup'

    It 'should execute tf validate for the expected modules'
      When run source "iac.tf.validate.sh"
      The output should include "Executing tf validate for: $WORKSPACE_PATH/IAC/Terraform/terraform/02_sql/01_deployment"
      The output should include "Executing tf validate for: $WORKSPACE_PATH/IAC/Terraform/terraform/03_webapp/01_deployment"
      The output should not include "Executing tf validate for: $WORKSPACE_PATH/IAC/Terraform/terraform//02_sql/01_deployment"
    End
  End

  Context "Test Harness - Extra Sql Folder"
    setup(){
      setup_root
      export WORKSPACE_PATH="$ROOT_WORKSPACE_PATH/.symphony/test_harness/extra_deployment"
      export RUN_ID=2
      unset EXCLUDED_FOLDERS
    }
    BeforeEach 'setup'

    It 'should execute tf validate for the expected modules, including 02_sql/02_foo'
      When run source "iac.tf.validate.sh"
      The output should include "Executing tf validate for: $WORKSPACE_PATH/IAC/Terraform/terraform/02_sql/01_deployment"
      The output should include "Executing tf validate for: $WORKSPACE_PATH/IAC/Terraform/terraform/02_sql/02_foo"
      The output should include "Executing tf validate for: $WORKSPACE_PATH/IAC/Terraform/terraform/03_webapp/01_deployment"
      The output should not include "Executing tf validate for: $WORKSPACE_PATH/IAC/Terraform/terraform//02_sql/01_deployment"
    End
  End  

  Context "Test Harness - exclude 02_foo deployment"
    setup(){
      setup_root
      export WORKSPACE_PATH="$ROOT_WORKSPACE_PATH/.symphony/test_harness/extra_deployment"
      export RUN_ID=2
      export EXCLUDED_FOLDERS="02_sql/02_foo,02_sql/01_deployment"
    }
    BeforeEach 'setup'

    It 'should exclude 02_sql/02_foo deployment'
      When run source "iac.tf.validate.sh"
      The output should not include "Executing tf validate for: $WORKSPACE_PATH/IAC/Terraform/terraform/02_sql/02_foo"
      The output should include "02_sql/02_foo excluded"
    End
  End   

  Context "Test Harness - skip __02_sql layer"
    setup(){
      setup_root
      export WORKSPACE_PATH="$ROOT_WORKSPACE_PATH/.symphony/test_harness/skip_02_sql"
      export RUN_ID=2
    }
    BeforeEach 'setup'

    It 'should skip the __02_sql layer'
      When run source "iac.tf.validate.sh"
      The output should not include "Executing tf validate for: $WORKSPACE_PATH/IAC/Terraform/terraform/__02_sql/01_deployment"
      The output should include "Skipping ./__02_sql/01_deployment"
    End
  End      
End
