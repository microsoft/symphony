#!/bin/bash

# pre_deploy method is called before the deployment
pre_deploy() {
  # placeholder for pre deploy logic
  echo "----- Running Pre Deploy Event -----------"
  export sqlServerAdministratorLogin="eshopadmin"
  export sqlServerAdministratorPassword="Test#@rdP@ssw0rd123!"
  return $?
}

# post_deploy method is called after the deployment
post_deploy() {
  # placeholder for post deploy logic
  return $?
}
