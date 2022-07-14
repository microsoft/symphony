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