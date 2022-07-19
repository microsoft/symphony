# Testing

## Bicep

All below test examples have assumption for working directory - should be [IAC/Bicep/test](./../IAC/Bicep/test)

### Azure Resource Manager Template Toolkit (arm-ttk)

The tests will check a template or set of templates for coding best practices using [arm-ttk](https://github.com/Azure/arm-ttk).

1. Generate ARM template based on Bicep

```powershell
az bicep build --file ../bicep/01_sql/02_deployment/main.bicep
```

1. Install ARM TTK module

```powershell
Import-Module .\arm-ttk\arm-ttk.psd1
```

1. Run the test

```powershell
Test-AzTemplate -TemplatePath ../bicep/01_sql/02_deployment/main.json
```

1. Cleanup

```powershell
Remove-Item -Force -Path ../bicep/01_sql/02_deployment/main.json
```

### Integration Tests with Pester

[Pester](https://pester.dev/docs/quick-start) is a testing and mocking framework for PowerShell.

1. Install Pester modeule

```powershell
Install-Module -Name Pester -AllowClobber -Force -Confirm:$False -SkipPublisherCheck
```

1. (option 1) Run the test

```powershell
Invoke-Pester -Path ./pester/SqlIntegration.Tests.ps1
```

1. (option 2) Run the test with JUnit report

```powershell
Invoke-Pester -Path ./pester/SqlIntegration.Tests.ps1 -OutputFile Test.xml -OutputFormat JUnitXml
```

### Integration Tests with ShellSpec

[ShellSpec](https://github.com/shellspec/shellspec) is a full-featured BDD unit testing framework for dash, bash, ksh, zsh and all POSIX shells that provides first-class features such as code coverage, mocking, parameterized test, parallel execution and more.

1. Install ShellSpec

```bash
curl -fsSL https://git.io/shellspec | sh -s -- --yes
```

1. (option 1) Run the test

```bash
shellspec -f d
```

1. (option 2) Run the test with JUnit report

```bash
shellspec -f j > tests.xml
```

## Terraform

All below test examples have assumption for working directory - should be [IAC/Terraform/test/terraform](./../IAC/Terraform/test/terraform/)

### Terratest

[Terratest](https://github.com/gruntwork-io/terratest)  is a Go library that makes it easier to write automated tests for your infrastructure code. It provides a variety of helper functions and patterns for common infrastructure testing tasks,and offers a good
support for the most commonly used Azure resources.

1. Ensure Go 1.16 is installed, and [Terratest Go environment](https://github.com/gruntwork-io/terratest/blob/master/examples/azure/README.md) is properly configured.

2. Run the tests.

```bash

go build 01_storage_integration_test.go

go test -v -run Test01_Init_Storage

```
