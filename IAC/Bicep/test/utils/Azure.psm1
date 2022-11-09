function Confirm-EnvironmentVariable($name){
    $value=[Environment]::GetEnvironmentVariable($name)
    if([string]::IsNullOrEmpty($value)) {
        Write-Error("Missing Required Environment Variable $name")
        exit -1
    }
    return $value
}
function Connect-AzAccountFromEnv() {
    $clientSecret=Confirm-EnvironmentVariable("ARM_CLIENT_SECRET")
    $clientId=Confirm-EnvironmentVariable("ARM_CLIENT_ID")
    $tenantId=Confirm-EnvironmentVariable("ARM_TENANT_ID")
    $subscriptionId=Confirm-EnvironmentVariable("ARM_SUBSCRIPTION_ID")

    $SecuredPassword = ConvertTo-SecureString $clientSecret -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential ($clientId, $SecuredPassword)
    Connect-AzAccount -ServicePrincipal -TenantId $tenantId -Credential $Credential
    Set-AzContext -Subscription $subscriptionId
}

function Get-ResourceGroup([string]$resourceGroupName) {
    $resource = Get-AzResourceGroup $resourceGroupName
    return $resource
}

function Get-ResourceGroupExists([string]$resourceGroupName) {
    $resource = Get-ResourceGroup $resourceGroupName

    return ($resource -ne $null)
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
    return ($resource -ne $null)
}

function Get-WebApp([string]$webAppName, [string]$resourceGroupName) {
    $resource = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName
    return $resource
}

function Get-WebAppExists([string]$webAppName, [string]$resourceGroupName) {
    $resource = Get-WebApp $webAppName $resourceGroupName
    return ($resource -ne $null)
}

function Get-SqlServer([string]$serverName, [string]$resourceGroupName) {
    $resource = Get-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $serverName
    return $resource
}

function Get-SqlServerExists([string]$serverName, [string]$resourceGroupName) {
    $resource = Get-SqlServer $serverName $resourceGroupName
    return ($resource -ne $null)
}

function Get-SqlDatabase([string]$databaseName, [string]$serverName, [string]$resourceGroupName) {
    $resource = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName
    return $resource
}

function Get-SqlDatabaseExists([string]$databaseName, [string]$serverName, [string]$resourceGroupName) {
    $resource = Get-SqlDatabase $databaseName $serverName $resourceGroupName
    return ($resource -ne $null)
}

Export-ModuleMember -Function `
    Get-ResourceGroup, Get-ResourceGroupExists, `
    Get-AppServicePlan, Get-AppServicePlanExists, `
    Get-WebApp, Get-WebAppExists, `
    Get-SqlServer, Get-SqlServerExists, `
    Get-SqlDatabase, Get-SqlDatabaseExists, `
    Connect-AzAccountFromEnv
