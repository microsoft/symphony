function Get-ResourceGroupExists([string]$resourceGroupName) {
    $rg = Get-AzResourceGroup $resourceGroupName
    if ($null -eq $rg) {
        throw "Resource group $resourceGroupName was not found!"
    }
    else{
        return $true
    }
}

Export-ModuleMember -Function Get-ResourceGroupExists

function Get-AppServicePlanExists {
    param (
        [string]$appServicePlanName,
        [string]$resourceGroupName
    )
    $resource = Get-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $appServicePlanName
    if ($null -eq $resource) {
        throw "Resource $resourceGroupName/$appServicePlanName was not found!"
    }
    else{
        return $true
    }
}

Export-ModuleMember -Function Get-AppServicePlanExists

function Get-WebAppExists([string]$webAppName, [string]$resourceGroupName) {
    $resource = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName
    if ($null -eq $resource) {
        throw "Resource $resourceGroupName/$appServicePlan was not found!"
    }
    else{
        return $true
    }
}

Export-ModuleMember -Function Get-WebAppExists
