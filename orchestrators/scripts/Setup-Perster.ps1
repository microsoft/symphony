if (!(Get-Module -Name Pester)) {
    Write-Host "Pester module does not exist. Installing ..."
    try {
        Install-Module -Name Pester -AllowClobber -Force -Confirm:$False -SkipPublisherCheck
    }
    catch [Exception] {
        $_.message 
        exit
    }
}
Import-Module Pester