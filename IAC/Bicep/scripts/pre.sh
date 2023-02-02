#!/bin/bash

sqlServerAdministratorLogin="testadmin"
sqlServerAdministratorPassword="Test#@rdP@ssw0rd123!"

if [ -n "${GITHUB_ACTION}" ]; then
    echo "sqlServerAdministratorLogin=${sqlServerAdministratorLogin}" >> "$GITHUB_ENV"
    echo "sqlServerAdministratorPassword=${sqlServerAdministratorPassword}" >> "$GITHUB_ENV"
elif [ -n "${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}" ]; then
    echo "##vso[task.setvariable variable=sqlServerAdministratorLogin;isOutput=true;issecret=true]${sqlServerAdministratorLogin}"
    echo "##vso[task.setvariable variable=sqlServerAdministratorPassword;isOutput=true;issecret=true]${sqlServerAdministratorPassword}"
fi