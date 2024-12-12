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

    It "should check the sql server is ready" {
      # act and assert
      $sqlServerResource = Confirm-AzBPSqlServer $sqlServerName $sqlServerResourceGroupName
      $sqlServerResource.ResourceDetails.PublicNetworkAccess | Should -Be "Enabled"
    }

    It "should check the identity database is online and ready" {
      # act and assert
      $identitydbResource = Confirm-AzBPSqlDatabase "identitydb" $sqlServerName $sqlServerResourceGroupName
      $identitydbResource.ResourceDetails.Status | Should -Be "Online"
    }

    It "should check the catalog database is online and ready" {
      # act and assert
      $catalogdbResource = Confirm-AzBPSqlDatabase "catalogdb" $sqlServerName $sqlServerResourceGroupName
      $catalogdbResource.ResourceDetails.Status | Should -Be "Online"
    }

    It "should check the app service plan is ready" {
      # act and assert
      $appServicePlanResource = Confirm-AzBPAppServicePlan $appServicePlanName $appServiceResourceGroupName
      $appServicePlanResource.ResourceDetails.Status | Should -Be "Ready"
    }

    It "should check the web app is running" {
      # act and assert
      $webAppResource = Confirm-AzBPWebApp $appServiceName $appServiceResourceGroupName
      $webAppResource.ResourceDetails.State | Should -Be "Running"
    }

    It "should check the web app has connection strings" {
      # act and assert
      $webAppResource = Confirm-AzBPWebApp $appServiceName $appServiceResourceGroupName
      $webAppResource.ResourceDetails.SiteConfig.ConnectionStrings | Should -Not -Be $null
    }

    It "should check the web app has two connection strings" {
      # act and assert
      $webAppResource = Confirm-AzBPWebApp $appServiceName $appServiceResourceGroupName
      $webAppResource.ResourceDetails.SiteConfig.ConnectionStrings.Count | Should -Be 2
    }

    It "should check the web app has the catalog connection string with the correct sql server name" {
      # act and assert
      $webAppResource = Confirm-AzBPWebApp $appServiceName $appServiceResourceGroupName
      $webAppResource.ResourceDetails.SiteConfig.ConnectionStrings | Where-Object { $_.name -eq 'CatalogConnection' } | Select-Object -ExpandProperty ConnectionString | Should -BeLike "*$sqlServerName*"
    }

    It "should check the web app has the identity connection string with the correct sql server name" {
      # act and assert
      $webAppResource = Confirm-AzBPWebApp $appServiceName $appServiceResourceGroupName
      $webAppResource.ResourceDetails.SiteConfig.ConnectionStrings | Where-Object { $_.name -eq 'IdentityConnection' } | Select-Object -ExpandProperty ConnectionString | Should -BeLike "*$sqlServerName*"
    }

    It "should check the web app has a host name" {
      # act and assert
      $webAppResource = Confirm-AzBPWebApp $appServiceName $appServiceResourceGroupName
      $webAppResource.ResourceDetails.DefaultHostName | Should -Not -Be $null
    }

    It "should check the web app works" {
      # act and assert
      $webAppResource = Confirm-AzBPWebApp $appServiceName $appServiceResourceGroupName
      $defaultHostName = $webAppResource.ResourceDetails.DefaultHostName
      $response = Invoke-RestMethod -Uri "http://$defaultHostName" -Method 'Get' -TimeoutSec 240
      $response | Should -Not -Be $null
    }
  }
}
