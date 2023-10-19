BeforeAll {
  Import-Module BenchPress.Azure

  # arrange
  $resourceGroupName = "rgwebapplayer"
  $appServicePlanName = "test-app-svc-plan-sbg"
  $appServiceName = "test-app-svc-wj3"

  # log
  Write-Host "Running 02_webapp Tests for {resourceGroupName: $resourceGroupName}, {appServicePlanName: $appServicePlanName}, {appServiceName: $appServiceName}"
}

Describe '02 Web Layer Tests' {
  it 'Should deploy a resource group for web layer' {
    #arrange
    $bicepPath = "../bicep/02_webapp/01_rg/main.bicep"
    $params = @{
      deploymentName    = "rgwebapplayer"
      resourceGroupName = $resourceGroupName
      location          = "westus"
      environment       = "test"
    }

    #act
    $deployment = Deploy-AzBPBicepFeature $bicepPath $params
    $resourceGroupExists = Get-ResourceGroupExists $resourceGroupName

    #assert
    $deployment.ProvisioningState | Should -Be "Succeeded"
    $resourceGroupExists | Should -Be $true
  }

  it 'Should deploy an app service' {
    #arrange
    $bicepPath = "../bicep/02_webapp/02_deployment/main.bicep"
    $params = @{
      deploymentName                     = "rgwebapplayer"
      location                           = "westus"
      environment                        = "test"
      appSvcPlanSkuName                  = "S1"
      appSvcPlanSkuTier                  = "Standard"
      appSvcDockerImage                  = "crsymphony360.azurecr.io/eshoppublicapi"
      appSvcDockerImageTag               = "a87f571"
      containerRegistryResourceGroupName = "devops-symphony-362"
      containerRegistryName              = "crsymphony360"
      sqlDatabaseCatalogDbName           = "sqlDatabaseCatalogDbName"
      sqlDatabaseIdentityDbName          = "sqlDatabaseIdentityDbName"
      sqlServerFqdn                      = "sqlServerFqdn"
      sqlServerAdministratorLogin        = "sqlServerAdministratorLogin"
      sqlServerAdministratorPassword     = "sqlServerAdministratorPassword"
    }

    #act
    $deployment = Deploy-AzBPBicepFeature $bicepPath $params $resourceGroupName
    $appServicePlanResourceExists = Get-AppServicePlanExists $appServicePlanName $resourceGroupName
    $webAppResourceExists = Get-WebAppExists $appServiceName $resourceGroupName

    #assert
    $deployment.ProvisioningState | Should -Be "Succeeded"
    $appServicePlanResourceExists | Should -Be $true
    $webAppResourceExists | Should -Be $true
  }
}

AfterAll {
  #clean up
  Write-Host "Cleaning up Resources!"

  Write-Host "Removing Resource Group $resourceGroupName"

  Remove-AzBPBicepFeature $resourceGroupName
}
