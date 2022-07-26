function Get-ResourceGroup([string]$resourceGroupName) {
    $resource = Get-AzResourceGroup $resourceGroupName
    return $resource
}

function Get-ResourceGroupExists([string]$resourceGroupName) {
    $resource = Get-ResourceGroup $resourceGroupName

    if ($resource -eq $null) {
        return $false
    } else {
        return $true
    }
}

function Get-AppServicePlan {
    param (
        [string]$appServicePlanName,
        [string]$resourceGroupName
    )
    $resource = Get-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $appServicePlanName
    return $resource
}

function Get-AppServicePlanExists {
    param (
        [string]$appServicePlanName,
        [string]$resourceGroupName
    )
    $resource = Get-AppServicePlan $appServicePlanName $resourceGroupName
    if ($resource -eq $null) {
        return $false
    } else{
        return $true
    }
}

function Get-WebApp([string]$webAppName, [string]$resourceGroupName) {
    $resource = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName
    return $resource
}

function Get-WebAppExists([string]$webAppName, [string]$resourceGroupName) {
    $resource = Get-WebApp $webAppName $resourceGroupName
    if ($resource -eq $null) {
        return $false
    }
    else{
        return $true
    }
}

Export-ModuleMember -Function Get-ResourceGroupExists, Get-AppServicePlanExists, Get-WebAppExists
