#!/bin/bash

# pre_deploy method is called before the deployment
pre_deploy() {
  # placeholder for pre deploy logic
  return $?
}

# post_deploy method is called after the deployment
post_deploy() {
  # placeholder for post deploy logic
  return $?
}

# pre_validate method is called before the deployment validation
pre_validate() {
  # placeholder for pre deployment validate logic
  export sqlDatabaseCatalogDbName="sqlDatabaseCatalogDbName"
  export sqlDatabaseIdentityDbName="sqlDatabaseIdentityDbName"
  export sqlServerFqdn="sqlServerFqdn"
  export sqlServerAdministratorLogin="eshop"
  export sqlServerAdministratorPassword="eshO@#12csdf"
  return $?
}

# post_validate method is called after the deployment validation
post_validate() {
  # placeholder for post deployment validate logic
  return $?
}
