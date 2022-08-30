# Setup Paths
$PSUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath "utils"

# Imports
Import-Module $PSUtilsPath/AzCli -Force
Import-Module $PSUtilsPath/Bicep -Force
Import-Module $PSUtilsPath/Azure -Force
