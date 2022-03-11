# Developer Experience

This repo has the following components to deploy the sample app using Symphony:

- [Official eShopOnWeb project](https://github.com/dotnet-architecture/eShopOnWeb)
- [Azure SQL Database](https://azure.microsoft.com/en-us/products/azure-sql/database)
- [Symphony layers (Terraform or Bicep) to deploy web app and database](./IAC/)
- Tests to perform tests for symphony layers
  - [golang (Terraform)](./IAC/Terraform/test)
  - [ShellSpec (Bicep)](./IAC/Bicep/test)
- [DevContainer to develop Symphony](./devcontainer)

## DevContainer

[DevContainer configuration](./.devcontainer/devcontainer.json) uses [Dockerfile](./.devcontainer/Dockerfile) to build the _DevContainer_.

_DevContainer_ image is based on _Ubuntu:bullseye_ image and has the following packages installed;

- golang 1.17.8
- Terraform 1.1.7
- TFLint 0.34.1
- TFLint Ruleset for terraform-provider-azurerm 0.14.0

_DevContainer_ also has the following _VSCode_ extensions installed to make the development experience better;

- hashicorp.terraform
- ms-vscode.azurecli
- ms-azuretools.vscode-azureterraform
- ms-azuretools.vscode-docker
- ms-dotnettools.vscode-dotnet-runtime
- ms-azuretools.vscode-bicep"
- ms-azuretools.vscode-docker"
- golang.Go
- mikestead.dotenv
