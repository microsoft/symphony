function Deploy-BicepFeature([string]$path, $params){
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($path)
    $folder = Split-Path $path
    $armPath  = Join-Path -Path $folder -ChildPath "$fileName.json"

    Write-Host "Tranpiling Bicep to Arm"
    az bicep build --file $path

    $code = $?
    if ($code -eq "True"){ # arm deployment was successful
        Write-Host "Deploying ARM Template"
        New-AzSubscriptionDeployment -Name $params.deploymentName -Location $params.location -TemplateFile "$armPath" -TemplateParameterObject $params -SkipTemplateParameterPrompt
    }
    # delete arm template json file, as it's no longer needed.
    Write-Host "Removing arm template json"
    rm "$armPath"
}

function Remove-BicepFeature($resourceGroupName){
    Get-AzResourceGroup -Name $resourceGroupName | Remove-AzResourceGroup -Force
}

Export-ModuleMember -Function Deploy-BicepFeature, Remove-BicepFeature