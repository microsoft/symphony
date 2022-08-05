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

function Get-SqlServer([string]$serverName, [string]$resourceGroupName) {
    $resource = Get-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $serverName
    return $resource
}

function Get-SqlServerExists([string]$serverName, [string]$resourceGroupName) {
    $resource = Get-SqlServer $serverName $resourceGroupName
    if ($resource -eq $null) {
        return $false
    }
    else{
        return $true
    }
}

function Get-SqlDatabase([string]$databaseName, [string]$serverName, [string]$resourceGroupName) {
    $resource = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName
    return $resource
}

function Get-SqlDatabaseExists([string]$databaseName, [string]$serverName, [string]$resourceGroupName) {
    $resource = Get-SqlDatabase $databaseName $serverName $resourceGroupName
    if ($resource -eq $null) {
        return $false
    }
    else{
        return $true
    }
}

Export-ModuleMember -Function `
    Get-ResourceGroup, Get-ResourceGroupExists, `
    Get-AppServicePlan, Get-AppServicePlanExists, `
    Get-WebApp, Get-WebAppExists, `
    Get-SqlServer, Get-SqlServerExists, `
    Get-SqlDatabase, Get-SqlDatabaseExists
