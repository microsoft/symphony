BeforeDiscovery {
    Import-Module $PSScriptRoot/AzCli -Force
}

BeforeAll {
    $resourceGroupName = "dev-rg-sql-zy4"
    $sqlServerName = "dev-sqlserver-tl3"
}

Describe "SQL Integration Tests" {
    Context "SQL Server" {
        It "SQL Server (<serverName>) should has state '<expected>'" -TestCases @(
            @{ ServerName = $sqlServerName; Expected = 'Ready'}
        ) {
            $azSqlServer = Invoke-AzCli -Command "sql server show --resource-group $resourceGroupName --name $sqlServerName"
            $azSqlServer.state | Should -Be $expected

            # Get-AzSqlServer does not contain 'state' property
            # $azSqlServer = Get-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $ServerName
            # $azSqlServer.State | Should -Be $expected
        }
    }

    Context "SQL Databases" {
        It "<databaseName> should has status '<expected>'" -TestCases @(
            @{ DatabaseName = "catalogdb"; Expected = 'Online'}
            @{ DatabaseName = "identitydb"; Expected = 'Online'}
        ) {
            # Option 1
            $azSqlDatabase = Invoke-AzCli -Command "sql db show --resource-group $resourceGroupName --server $sqlServerName --name $databaseName"
            $azSqlDatabase.status | Should -Be $expected

            # Option 2
            # $azSqlDatabase = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $sqlServerName -DatabaseName $databaseName
            # $azSqlDatabase.Status | Should -Be $expected
        }
    }
}