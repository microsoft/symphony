function Deploy-BicepFeature([string]$path, $params, $resourceGroupName){
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($path)
    $folder = Split-Path $path
    $armPath  = Join-Path -Path $folder -ChildPath "$fileName.json"

    Write-Host "Tranpiling Bicep to Arm"
    az bicep build --file $path

    $code = $?
    if ($code -eq "True"){
        $location = $params.location
        $deploymentName = $params.deploymentName

        Write-Host "Deploying ARM Template ($deploymentName) to $location"

        if ([string]::IsNullOrEmpty($resourceGroupName)){
            New-AzSubscriptionDeployment -Name "$deploymentName" -Location "$location" -TemplateFile "$armPath" -TemplateParameterObject $params -SkipTemplateParameterPrompt
        }
        else{
            New-AzResourceGroupDeployment -Name "$deploymentName" -ResourceGroupName "$resourceGroupName" -TemplateFile "$armPath" -TemplateParameterObject $params -SkipTemplateParameterPrompt
        }
    }

    Write-Host "Removing arm template json"
    rm "$armPath"
}

function Remove-BicepFeature($resourceGroupName){
    Get-AzResourceGroup -Name $resourceGroupName | Remove-AzResourceGroup -Force
}

Export-ModuleMember -Function Deploy-BicepFeature, Remove-BicepFeature
