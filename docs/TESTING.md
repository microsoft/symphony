# IaC Testing

Like any code, IaC changes can introduce errors, failures, or breaking changes. Automated tests are an essential component of IaC to ensure code quality and reduce the risk of deployment failures, downtime, and associated costs. By detecting errors, failures, or breaking changes early in the process, automated tests can improve the readiness of deployed resources and ensure better service stability.

Symphony offers samples that help to write and execute both module and end-to-end tests for IaC module code and demonstrate how the tests can be integrated into the symphony workflows.

## Module tests

Module tests ensure that module code/configuration will create the resources successfully.

- [X] Module tests deploy the module resources, then validate the deployed resources & configurations, and finally tear down any deployed resources.
- [X] Slow to execute, but can be executed in parallel.
- [X] Have no dependency on any resource other than the module under test resources.

## End to End tests

End to End tests ensure that all resources deployed by one or more modules are working as expected.

- [X] End to End tests validate already deployed resources for a long-lived environment e.g. development or production
- [X] Fast to execute, and can be executed in parallel.
- [X] Depend on multiple modules, and sometimes the entire system resources.

## Bicep

All below test examples have an assumption for the working directory - should be [IAC/Bicep/test](./../IAC/Bicep/test)

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

### End to End Tests with Pester

[Pester](https://pester.dev/docs/quick-start) is a testing and mocking framework for PowerShell.

1. Install Pester module

    ```powershell
    Install-Module -Name Pester -AllowClobber -Force -Confirm:$False -SkipPublisherCheck
    ```

1. (option 1) Run the test

    ```powershell
    Invoke-Pester -Path ./pester/SqlIntegration.Tests.ps1
    ```

1. (option 2) Run the test with the JUnit report

    ```powershell
    Invoke-Pester -Path ./pester/SqlIntegration.Tests.ps1 -OutputFile Test.xml -OutputFormat JUnitXml
    ```

### End to End test with ShellSpec

[ShellSpec](https://github.com/shellspec/shellspec) is a full-featured BDD unit testing framework for the dash, bash, ksh, zsh and all POSIX shells that provide first-class features such as code coverage, mocking, parameterized test, parallel execution and more.

1. Install ShellSpec

    ```bash
    curl -fsSL https://git.io/shellspec | sh -s -- --yes
    ```

1. (option 1) Run the test

    ```bash
    shellspec -f d
    ```

1. (option 2) Run the test with the JUnit report

    ```bash
    shellspec -f j > tests.xml
    ```

## Terraform

All below test examples have an assumption for the working directory - should be [IAC/Terraform/test/terraform](./../IAC/Terraform/test/terraform/)

### End to End tests with Terratest

[Terratest](https://github.com/gruntwork-io/terratest) is a Go library that makes it easier to write automated tests for your infrastructure code. It provides a variety of helper functions and patterns for common infrastructure testing tasks, and offers good support for the most commonly used Azure resources.

1. Ensure Go 1.16 is installed, and the [Terratest Go environment](https://github.com/gruntwork-io/terratest/blob/master/examples/azure/README.md) is properly configured.

1. Run the tests.

    ```bash
    go test -v -timeout 1000s --tags=e2e_test
    ```
