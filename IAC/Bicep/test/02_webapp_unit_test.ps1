BeforeAll{
    . $PSScriptRoot/UtilsLoader.ps1
    $ResourceGroupName = "rgwebapplayer"
}

Describe '02 Web Layer Tests' {
    it 'Should deploy a resource group for web layer' {
        #arrange
        $bicepPath = "../bicep/02_webapp/01_rg/main.bicep"
        $params = @{
            deploymentName = "rgwebapplayer"
            resourceGroupName = $ResourceGroupName
            location = "westus"
            environment = "dev"
        }
        #act
        $deployment = Deploy-BicepFeature $bicepPath $params
        #assert
        $deployment.ProvisioningState | Should -Be "Succeeded"
    } 

    it 'Should deploy an app service' {
        #arrange
        $bicepPath = "../bicep/02_webapp/02_deployment/main.bicep"
        $params = @{
            deploymentName = "rgwebapplayer"
            resourceGroupName = $ResourceGroupName
            location = "westus"
            environment = "dev"
        }
        $deployed = $True
        #act
        #to do
        #assert
        $deployed | Should -Be $True
    } 
}

AfterAll{
    #clean up
    Write-Host "Cleaning up Resources!"

    Write-Host "Removing Resource Group $ResourceGroupName"
    #Remove-BicepFeature $ResourceGroupName
}
