$AZ_MODULE_PATH=$(Get-Module -ListAvailable -Name Az | Select-Object -ExpandProperty Path)
if (-not $AZ_MODULE_PATH) {
  Install-Module -Name Az -AllowClobber -Force -Confirm:$False -SkipPublisherCheck
}

$AZ_APP_MODULE_PATH=$(Get-Module -ListAvailable -Name Az.App | Select-Object -ExpandProperty Path)
if (-not $AZ_APP_MODULE_PATH) {
  Install-Module -Name Az.App -AllowClobber -Force -Confirm:$False -SkipPublisherCheck
}

$AZ_PORTAL_MODULE_PATH=$(Get-Module -ListAvailable -Name Az.Portal | Select-Object -ExpandProperty Path)
if (-not $AZ_PORTAL_MODULE_PATH) {
  Install-Module -Name Az.Portal -AllowClobber -Force -Confirm:$False -SkipPublisherCheck
}

$BENCHPRESS_AZURE_MODULE_PATH=$(Get-Module -ListAvailable -Name BenchPress.Azure | Select-Object -ExpandProperty Path)
if (-not $BENCHPRESS_AZURE_MODULE_PATH) {
  Install-Module -Name BenchPress.Azure -AllowClobber -Force -Confirm:$False -SkipPublisherCheck
}
