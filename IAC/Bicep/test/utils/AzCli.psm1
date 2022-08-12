function Invoke-AzCli($Command) {
    $toExecute = "az $Command"
    $result = Invoke-Expression "$toExecute"
    if ($LastExitCode -gt 0) {
        Write-Error $result
        Exit 1
    }
    $result | ConvertFrom-Json
}

Export-ModuleMember -Function Invoke-AzCli
