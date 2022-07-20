# Setup Paths
$PSScriptParent = Split-Path $PSScriptRoot
$PSUtilsPath = Join-Path -Path $PSScriptParent -ChildPath "utils"

# Imports
Import-Module $PSUtilsPath/AzCli -Force
