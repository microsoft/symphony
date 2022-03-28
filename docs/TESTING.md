# Testing

## Bicep

All below test examples have assumption for working directory - should be [IAC/Bicep/test](./../IAC/Bicep/test)

### Azure Resource Manager Template Toolkit (arm-ttk)

The tests will check a template or set of templates for coding best practices using [arm-ttk](https://github.com/Azure/arm-ttk).

1. Generate ARM template based on Bicep

```powershell
az bicep build --file ../bicep/01_sql/02_deployment/main.bicep
```

2. Install ARM TTK module

```powershell
Import-Module .\arm-ttk\arm-ttk.psd12. Run the test
```

3. Run the test

```powershell
Test-AzTemplate -TemplatePath ../bicep/01_sql/02_deployment/main.json
```

4. Cleanup

```powershell
Remove-Item -Force -Path ../bicep/01_sql/02_deployment/main.json
```

### Integration Tests with Pester

[Pester](https://pester.dev/docs/quick-start) is a testing and mocking framework for PowerShell.

1. Install Pester modeule

```powershell
Install-Module -Name Pester -AllowClobber -Force -Confirm:$False -SkipPublisherCheck
```

2. (option 1) Run the test

```powershell
Invoke-Pester -Path ./pester/SqlIntegration.Tests.ps1
```

3. (option 2) Run the test with JUnit report

```powershell
Invoke-Pester -Path ./pester/SqlIntegration.Tests.ps1 -OutputFile Test.xml -OutputFormat JUnitXml
```

### Integration Tests with ShellSpec

[ShellSpec](https://github.com/shellspec/shellspec) is a full-featured BDD unit testing framework for dash, bash, ksh, zsh and all POSIX shells that provides first-class features such as code coverage, mocking, parameterized test, parallel execution and more.

1. Install ShellSpec

```bash
curl -fsSL https://git.io/shellspec | sh -s -- --yes
```

2. (option 1) Run the test

```bash
shellspec -f d
```

3. (option 2) Run the test with JUnit report

```bash
shellspec -f j > tests.xml
```
