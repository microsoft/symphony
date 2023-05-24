# shellcheck shell=sh

# Defining variables and functions here will affect all specfiles.
# Change shell options inside a function may cause different behavior,
# so it is better to set them here.
# set -eu

# This callback function will be invoked only once before loading specfiles.
spec_helper_precheck() {
  # Available functions: info, warn, error, abort, setenv, unsetenv
  # Available variables: VERSION, SHELL_TYPE, SHELL_VERSION
  : minimum_version "0.28.1"
  project_root="$(pwd)/.."

  if [[ -d "$project_root/.symphony/test_harness" ]]; then
    rm -rf "$project_root/.symphony/test_harness"
  fi

  mkdir -p "$project_root/.symphony/test_harness/extra_deployment/IAC/Terraform/terraform"
  mkdir -p "$project_root/.symphony/test_harness/skip_02_sql/IAC/Terraform/terraform"

  cp -R "$project_root/IAC/Terraform/terraform" "$project_root/.symphony/test_harness/extra_deployment/IAC/Terraform"
  cp -R "$project_root/IAC/Terraform/terraform" "$project_root/.symphony/test_harness/skip_02_sql/IAC/Terraform"

  cp -R "$project_root/.symphony/test_harness/extra_deployment/IAC/Terraform/terraform/02_sql/01_deployment" "$project_root/.symphony/test_harness/extra_deployment/IAC/Terraform/terraform/02_sql/02_foo"
  mv "$project_root/.symphony/test_harness/skip_02_sql/IAC/Terraform/terraform/02_sql/" "$project_root/.symphony/test_harness/skip_02_sql/IAC/Terraform/terraform/__02_sql/"
  cp -R "$project_root/.symphony/test_harness/skip_02_sql/IAC/Terraform/terraform/__02_sql/01_deployment" "$project_root/.symphony/test_harness/skip_02_sql/IAC/Terraform/terraform/__02_sql/02_foo"
}

# This callback function will be invoked after a specfile has been loaded.
spec_helper_loaded() {
  :
}

# This callback function will be invoked after core modules has been loaded.
spec_helper_configure() {
  # Available functions: import, before_each, after_each, before_all, after_all
  : import 'support/custom_matcher'


}
