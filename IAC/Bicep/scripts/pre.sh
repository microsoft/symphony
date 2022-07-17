#!/bin/bash

sqlServerAdministratorLogin="testadmin"
sqlServerAdministratorPassword="Test#@rdP@ssw0rd123!"

echo "sqlServerAdministratorLogin=${sqlServerAdministratorLogin}" >> "$GITHUB_ENV"
echo "sqlServerAdministratorPassword=${sqlServerAdministratorPassword}" >> "$GITHUB_ENV"
