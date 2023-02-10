#!/bin/bash

# pre_deploy method is called before the deployment
pre_deploy() {
  # placeholder for pre deploy logic
  export sqlServerAdministratorLogin="eshop"
  export sqlServerAdministratorPassword="$(head -c 10 /dev/urandom | base64)"

  return $?
}

# post_deploy method is called after the deployment
post_deploy() {
  # placeholder for post deploy logic
  return $?
}
