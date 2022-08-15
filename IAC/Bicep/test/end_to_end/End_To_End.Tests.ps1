BeforeDiscovery {
    . $PSScriptRoot/UtilsLoader.ps1
}

BeforeAll {
    $sqlServerResourceGroupName = $env:SQLSERVER_RESOURCE_GROUP_NAME
    $sqlServerName = $env:SQLSERVER_NAME
    $resourceGroupName = $env:APPSERVICE_RESOURCE_GROUP_NAME
    $appServicePlanName = $env:APPSERVICE_PLAN_NAME
    $appServiceName = $env:APPSERVICE_NAME
}

Describe "End to End Tests" {
    Context "Test end to end" {
        It "should check the parameters and environment variables configured correctly" {
          $sqlServerResourceGroupName | Should -Not -Be $Null
          $sqlServerName | Should -Not -Be $Null
        }

        It "should check the azure powershell connected and configured correctly" {
          $currentContext = Get-AzContext
          $currentContext | Should -Not -Be $Null
        }

        It "resources should be ready and online, and web app works" {
            $sqlServerResource = Get-SqlServer $sqlServerName $sqlServerResourceGroupName
            $sqlServerResource.PublicNetworkAccess | Should -Be "Enabled"

            $identitydbResource = Get-SqlDatabase "identitydb" $sqlServerName $sqlServerResourceGroupName
            $identitydbResource.Status | Should -Be "Online"

            $catalogdbResource = Get-SqlDatabase "catalogdb" $sqlServerName $sqlServerResourceGroupName
            $catalogdbResource.Status | Should -Be "Online"

            $appServicePlanResource = Get-AppServicePlan $appServicePlanName $resourceGroupName
            $appServicePlanResource.Status | Should -Be "Ready"
            
            $webAppResource = Get-WebApp $appServiceName $resourceGroupName
            $webAppResource.State | Should -Be "Running"

            $defaultHostName = $webAppResource.DefaultHostName
            $defaultHostName | Should -Not -Be $Null

            $response = Invoke-RestMethod -Uri "http://$defaultHostName/swagger/index.html" -Method Get;
        }
    }
}
