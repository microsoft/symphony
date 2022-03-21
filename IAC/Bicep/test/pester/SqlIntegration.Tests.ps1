
BeforeAll {
    $resourceGroupName = "dev-rg-sql-zy4"
    $sqlServerName = "dev-sqlserver-tl3"
}

# BeforeDiscovery {
#     $resourceGroupName = "dev-rg-sql-zy4"
#     $sqlServerName = "dev-sqlserver-tl3"
# }

Describe "SQL Integration Tests" {
    Context "SQL Server" {
        It "SQL Server (<serverName>) should has state '<expected>'" -TestCases @(
            @{ ServerName = $sqlServerName; Expected = 'Ready'}
        ) {
            $azSqlServer = Get-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $ServerName
            $azSqlServer.ServerVersion | Should -Be $expected
        }
    }

    Context "SQL Databases" {
        It "<databaseName> should has status '<expected>'" -TestCases @(
            @{ DatabaseName = "catalogdb"; Expected = 'Online'}
            @{ DatabaseName = "identitydb"; Expected = 'Online'}
        ) {
            $azSqlDatabase = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $sqlServerName -DatabaseName $databaseName
            $azSqlDatabase.Status | Should -Be $expected
        }
    }
}