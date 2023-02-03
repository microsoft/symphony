#!/bin/bash

# pre_deploy method is called before the deployment
pre_deploy() {
  # placeholder for pre deploy logic

  export sqlServerAdministratorLogin="testadmin"
  export sqlServerAdministratorPassword="Test#@rdP@ssw0rd123!"
}

# post_deploy method is called after the deployment
post_deploy() {
  # placeholder for post deploy logic
}
