BeforeAll{
    . $PSScriptRoot/UtilsLoader.ps1
    $ResourceGroupName = "rglayer"
}

Describe '01 Sql Layer Tests' {
    it 'Should deploy a resource group for sql' {
        #arrange
        $bicepPath = "../bicep/01_sql/01_rg/main.bicep"
        $params = @{
            deploymentName = "rgtestlayer"
            resourceGroupName = $ResourceGroupName
            location = "westus"
            environment = "dev"
        }
        #act
        $deployment = Deploy-BicepFeature $bicepPath $params
        #assert
        $deployment.ProvisioningState| Should -Be "Succeeded"
    } 

    it 'Should deploy a sql server' {
        #arrange
        $deployed = $True
        #act
        #to do
        #assert
        $deployed| Should -Be $True
    } 
}

AfterAll{
    #clean up
    Write-Host "Cleaning up Resources!"

    Write-Host "Removing Resource Group $ResourceGroupName"
    Remove-BicepFeature $ResourceGroupName
}
