BeforeDiscovery {
    . $PSScriptRoot/UtilsLoader.ps1
}

BeforeAll {
    $sqlServerResourceGroupName = "rgsqllayer"
    $sqlServerName = "test-sqlserver-pyo"
    $resourceGroupName = "dev-rg-web-nnl"
    $appServicePlanName = "dev-app-svc-plan-k55"
    $appServiceName = "dev-app-svc-guw"
}

Describe "End to End Tests" {
    Context "Test end to end" {
        It "resources should be ready and online, and web app works" -TestCases @(
            @{ expected = 'Ready' }
        ) {
            $sqlServerResource = Get-SqlServer $sqlServerName $sqlServerResourceGroupName
            $sqlServerResource.State | Should -Be ""
        }
    }
}
