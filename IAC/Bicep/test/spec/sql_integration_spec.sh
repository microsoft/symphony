#!/usr/bin/env bash

Describe 'SQL Integration Tests'
    setup(){
      export SQL_SERVER_RG_NAME="${sqlServerResourceGroupName}"
      export SQL_SERVER_NAME="${sqlServerName}"
    }
    BeforeEach 'setup'

    Context 'SQL Server'
      It "SQL Server should has state 'Ready'"
        When call get_sql_server_by_name "${SQL_SERVER_RG_NAME}" "${SQL_SERVER_NAME}"
        The output should include_json '.state' 'Ready'
      End
    End

    Context 'SQL Databases'
      It "CatalogDB should has status 'Online'"
        When call get_sql_database_by_name "${SQL_SERVER_RG_NAME}" "${SQL_SERVER_NAME}" "catalogdb"
        The output should include_json '.status' 'Online'
      End

      It "IdentityDB should has status 'Online'"
        When call get_sql_database_by_name "${SQL_SERVER_RG_NAME}" "${SQL_SERVER_NAME}" "identitydb"
        The output should include_json '.status' 'Online'
      End
    End
End
