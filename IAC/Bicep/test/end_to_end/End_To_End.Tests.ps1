BeforeAll {
  Import-Module BenchPress.Azure

  # arrange
  $sqlServerResourceGroupName = $env:sqlServerResourceGroupName
  $sqlServerName = $env:sqlServerName
  $appServiceResourceGroupName = $env:appServiceResourceGroupName
  $appServicePlanName = $env:appServicePlanName
  $appServiceName = $env:appServiceName
}

Describe "End to End Tests" {
  Context "Test end to end" {
    It "should check the parameters and environment variables configured correctly" {
      # act and assert
      $sqlServerResourceGroupName | Should -Not -Be $Null
      $sqlServerName | Should -Not -Be $Null
    }

    It "should check the azure powershell connected and configured correctly" {
      # act and assert

      $currentContext = Get-AzContext
      $currentContext | Should -Not -Be $Null
    }

    It "resources should be ready and online, and web app works" {
      # act and assert
      $sqlServerResource = Confirm-AzBPSqlServer $sqlServerName $sqlServerResourceGroupName
      $sqlServerResource.ResourceDetails.PublicNetworkAccess | Should -Be "Enabled"

      # act and assert
      $identitydbResource = Confirm-AzBPSqlDatabase "identitydb" $sqlServerName $sqlServerResourceGroupName
      $identitydbResource.ResourceDetails.Status | Should -Be "Online"

      # act and assert
      $catalogdbResource = Confirm-AzBPSqlDatabase "catalogdb" $sqlServerName $sqlServerResourceGroupName
      $catalogdbResource.ResourceDetails.Status | Should -Be "Online"

      # act and assert
      $appServicePlanResource = Confirm-AzBPAppServicePlan $appServicePlanName $appServiceResourceGroupName
      $appServicePlanResource.ResourceDetails.Status | Should -Be "Ready"

      # act and assert
      $webAppResource = Confirm-AzBPWebApp $appServiceName $appServiceResourceGroupName
      $webAppResource.ResourceDetails.State | Should -Be "Running"

      # act and assert
      $defaultHostName = $webAppResource.ResourceDetails.DefaultHostName
      $defaultHostName | Should -Not -Be $null

      # act and assert
      $response = Invoke-RestMethod -Uri "http://$defaultHostName" -Method 'Get' -TimeoutSec 240
      $response | Should -Not -Be $null
    }
  }
}
