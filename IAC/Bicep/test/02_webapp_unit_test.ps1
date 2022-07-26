BeforeAll {
    . $PSScriptRoot/UtilsLoader.ps1
    $resourceGroupName = "rgwebapplayer"
    $appServicePlanName = "test-app-svc-plan-sbg"
    $appServiceName = "test-app-svc-wj3"
}

Describe '02 Web Layer Tests' {
    it 'Should deploy a resource group for web layer' {
        #arrange
        $bicepPath = "../bicep/02_webapp/01_rg/main.bicep"
        $params = @{
            deploymentName = "rgwebapplayer"
            resourceGroupName = $resourceGroupName
            location = "westus"
            environment = "test"
        }

        #act
        $deployment = Deploy-BicepFeature $bicepPath $params
        $resourceExists = Get-AppServicePlanExists $appServicePlanName $resourceGroupName

        #assert
        $deployment.ProvisioningState | Should -Be "Succeeded"
        $resourceExists | Should -Be $true
    }

    it 'Should deploy an app service' {
        #arrange
        $bicepPath = "../bicep/02_webapp/02_deployment/main.bicep"
        $params = @{
            deploymentName = "rgwebapplayer"
            location = "westus"
            environment = "test"
            appSvcPlanSkuName = "S1"
            appSvcPlanSkuTier = "Standard"
            appSvcDockerImage = "crsymphony362.azurecr.io/eshoppublicapi"
            appSvcDockerImageTag = "a87f571"
            containerRegistryResourceGroupName = "devops-symphony-362"
            containerRegistryName = "crsymphony362"
            sqlDatabaseCatalogDbName = "sqlDatabaseCatalogDbName"
            sqlDatabaseIdentityDbName = "sqlDatabaseIdentityDbName"
            sqlServerFqdn = "sqlServerFqdn"
            sqlServerAdministratorLogin = "sqlServerAdministratorLogin"
            sqlServerAdministratorPassword = "sqlServerAdministratorPassword"
        }

        #act
        $deployment = Deploy-BicepFeature $bicepPath $params $resourceGroupName
        $resourceExists = Get-WebAppExists $appServiceName $resourceGroupName

        #assert
        $deployment.ProvisioningState | Should -Be "Succeeded"
        $resourceExists | Should -Be $true
    }
}

AfterAll {
    #clean up
    Write-Host "Cleaning up Resources!"

    Write-Host "Removing Resource Group $resourceGroupName"
    Remove-BicepFeature $resourceGroupName
}
