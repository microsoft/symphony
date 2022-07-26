# Setup Paths
$PSScriptParent = Split-Path $PSScriptRoot
$PSUtilsPath = Join-Path -Path $PSScriptParent -ChildPath "utils"

# Imports
Import-Module $PSUtilsPath/AzCli -Force
Import-Module $PSUtilsPath/Bicep -Force
Import-Module $PSUtilsPath/Azure -Force
