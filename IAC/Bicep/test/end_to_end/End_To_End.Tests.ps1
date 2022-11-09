BeforeDiscovery {
    . $PSScriptRoot/UtilsLoader.ps1
}

BeforeAll {
    Connect-AzAccountFromEnv

    $sqlServerResourceGroupName = $env:sqlServerResourceGroupName
    $sqlServerName = $env:sqlServerName
    $appServiceResourceGroupName = $env:appServiceResourceGroupName
    $appServicePlanName = $env:appServicePlanName
    $appServiceName = $env:appServiceName
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

            $appServicePlanResource = Get-AppServicePlan $appServicePlanName $appServiceResourceGroupName
            $appServicePlanResource.Status | Should -Be "Ready"
            
            $webAppResource = Get-WebApp $appServiceName $appServiceResourceGroupName
            $webAppResource.State | Should -Be "Running"

            $defaultHostName = $webAppResource.DefaultHostName
            $defaultHostName | Should -Not -Be $Null

            $response = Invoke-RestMethod -Uri "http://$defaultHostName" -Method 'Get' -TimeoutSec 240
        }
    }
}
