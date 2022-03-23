# ARM-TTK

https://github.com/Azure/arm-ttk

```powershell
az bicep build --file ../bicep/01_sql/02_deployment/main.bicep
Import-Module .\arm-ttk\arm-ttk.psd1
Test-AzTemplate -TemplatePath ../bicep/01_sql/02_deployment/main.json
Remove-Item -Force -Path ../bicep/01_sql/02_deployment/main.json
```

# Pester

https://pester.dev/docs/quick-start

```powershell
# az login --use-device-code
# az account set --subscription 802fee76-8ce7-4508-b2de-ef2c10aede2a
# Connect-AzAccount -UseDeviceAuthentication
# Set-AzContext -Subscription "802fee76-8ce7-4508-b2de-ef2c10aede2a"

# Install Pester
# Install-Module -Name Pester -AllowClobber -Force -Confirm:$False -SkipPublisherCheck

Invoke-Pester -Path ./pester/SqlIntegration.Tests.ps1
Invoke-Pester -Path ./pester/SqlIntegration.Tests.ps1 -OutputFile Test.xml -OutputFormat JUnitXml

```

# ShellSpec

https://github.com/shellspec/shellspec
https://github.com/hattan/azureverify

```bash
# Install shellspec
# curl -fsSL https://git.io/shellspec | sh -s -- --yes

shellspec -f d
shellspec -f j > tests.xml
```