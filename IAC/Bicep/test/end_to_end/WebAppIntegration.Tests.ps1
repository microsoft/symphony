BeforeDiscovery {
    . $PSScriptRoot/UtilsLoader.ps1
}

BeforeAll {
    $resourceGroupName = "dev-rg-web-nnl"
    $appServicePlanName = "dev-app-svc-plan-k55"
    $appServiceName = "dev-app-svc-guw"
}

Describe "Web App Layer Tests" {
    Context "App Service Plan" {
        It "App Service Plan (<appServicePlanName>) should has state '<expected>'" -TestCases @(
            @{ expected = 'Ready'}
        ) {
            $azAppServicePlan = Invoke-AzCli -Command "appservice plan show --resource-group $resourceGroupName --name $appServicePlanName"
            $azAppServicePlan.properties.status | Should -Be $expected
        }
    }

    Context "App Service" {
        It "<appServiceName> should has status '<expected>'" -TestCases @(
            @{ expected = 'Running'}
        ) {
            $azAppService = Invoke-AzCli -Command "webapp show --resource-group $resourceGroupName --name $appServiceName"
            $azAppService.state | Should -Be $expected
        }
    }
}
