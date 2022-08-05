BeforeDiscovery {
    . $PSScriptRoot/UtilsLoader.ps1
}

BeforeAll {
    $resourceGroupName = "rgsqllayer"
    $sqlServerName = "test-sqlserver-pyo"
    $databaseName1 = "catalogdb"
    $databaseName2 = "identitydb"
}

Describe "SQL Integration Tests" {
    Context "SQL Server" {
        It "SQL Server (<serverName>) should has state '<expected>'" -TestCases @(
            @{ expected = 'Ready' }
        ) {
            $azSqlServer = Invoke-AzCli -Command "sql server show --resource-group $resourceGroupName --name $sqlServerName"
            $azSqlServer.state | Should -Be $expected

            $sqlServer = Get-SqlServerExists $sqlServerName $resourceGroupName
            $sqlServer | Should -Be $True
        }
    }

    Context "SQL Databases" {
        It "<databaseName> should has status '<expected>'" -TestCases @(
            @{ ServerName = $sqlServerName; DatabaseName = "catalogdb"; Expected = 'Online'}
            @{ ServerName = $sqlServerName; DatabaseName = "identitydb"; Expected = 'Online'}
        ) {
            $azSqlDatabase1 = Invoke-AzCli -Command "sql db show --resource-group $resourceGroupName --server $sqlServerName --name $databaseName1"
            $azSqlDatabase1.status | Should -Be $expected

            $azSqlDatabase2 = Invoke-AzCli -Command "sql db show --resource-group $resourceGroupName --server $sqlServerName --name $databaseName2"
            $azSqlDatabase2.status | Should -Be $expected

            $sqlDatabase1 = Get-SqlDatabaseExists $databaseName1 $sqlServerName $resourceGroupName
            $sqlDatabase1 | Should -Be $True

            $sqlDatabase2 = Get-SqlDatabaseExists $databaseName2 $sqlServerName $resourceGroupName
            $sqlDatabase2 | Should -Be $True
        }
    }
}
