BeforeAll {
  Import-Module BenchPress.Azure

  # arrange
  $resourceGroupName = "rgsqllayer"
  $sqlServerName = "test-sqlserver-pyo"
  $sqlDatabaseName1 = "catalogdb"
  $sqlDatabaseName2 = "identitydb"

  # log
  Write-Host "Running 01_sql Tests for {resourceGroupName: $resourceGroupName}, {sqlServerName: $sqlServerName}, {sqlDatabaseName1: $sqlDatabaseName1}, {sqlDatabaseName2: $sqlDatabaseName2}"
}

Describe '01 Sql Layer Tests' {
  it 'Should deploy a resource group for sql' {
    #arrange
    $bicepPath = "../bicep/01_sql/01_rg/main.bicep"
    $params = @{
      deploymentName    = "rgtestlayer"
      resourceGroupName = $resourceGroupName
      location          = "westus"
      environment       = "dev"
    }

    #act
    $deployment = Deploy-BicepFeature $bicepPath $params
    $resourceGroupExists = Confirm-AzBPResource $resourceGroupName

    #assert
    $deployment.ProvisioningState | Should -Be "Succeeded"
    $resourceGroupExists | Should -Be $true
  }

  it 'Should deploy a sql server' {
    #arrange
    $bicepPath = "../bicep/01_sql/02_deployment/main.bicep"
    $params = @{
      deploymentName                 = "sqltestlayer"
      location                       = "westus"
      environment                    = "test"
      sqlServerAdministratorLogin    = "sqladmin"
      sqlServerAdministratorPassword = "Sql@dmin123"
    }

    #act
    $deployment = Deploy-BicepFeature $bicepPath $params $resourceGroupName

    $sqlServerExists = Get-SqlServerExists $sqlServerName $resourceGroupName
    $sqlDatabaseExists1 = Get-SqlDatabaseExists $sqlDatabaseName1 $sqlServerName $resourceGroupName
    $sqlDatabaseExists2 = Get-SqlDatabaseExists $sqlDatabaseName2 $sqlServerName $resourceGroupName

    #assert
    $deployment.ProvisioningState | Should -Be "Succeeded"
    $sqlServerExists | Should -Be $true
    $sqlDatabaseExists1 | Should -Be $true
    $sqlDatabaseExists2 | Should -Be $true
  }
}

AfterAll {
  #clean up
  Write-Host "Cleaning up Resources!"

  Write-Host "Removing Resource Group $resourceGroupName"

  Remove-BicepFeature $resourceGroupName
}
