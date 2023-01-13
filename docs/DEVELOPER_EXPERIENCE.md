# Developer Experience

## DevContainer

[DevContainer configuration](./../.devcontainer/devcontainer.json) uses [Dockerfile](./../.devcontainer/Dockerfile) to build the _DevContainer_.

_DevContainer_ image is based on _Ubuntu:bullseye_ image and has the following packages installed:

- [golang 1.17.8](https://go.dev/)
- [Terraform 1.1.7](https://www.terraform.io/)
- [TFLint 0.34.1](https://github.com/terraform-linters/tflint)
- [TFLint Ruleset for terraform-provider-azurerm 0.14.0](https://github.com/terraform-linters/tflint-ruleset-azurerm)
- [Terragrunt 0.36.3](https://terragrunt.gruntwork.io/)
- [Azure CLI 2.34.1](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure Bicep CLI 0.4.1272](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
- [GitHub CLI 2.5.2](https://cli.github.com/)
- [PowerShell 7.2.1](https://github.com/PowerShell/PowerShell)
- [.NET 6.0](https://dotnet.microsoft.com/en-us/download/dotnet)

_DevContainer_ also has the following _VSCode_ extensions installed to make the development experience better:

- [hashicorp.terraform](https://marketplace.visualstudio.com/items?itemName=hashicorp.terraform)
- [ms-azuretools.vscode-azureterraform](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureterraform)
- [ms-dotnettools.vscode-dotnet-runtime](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.vscode-dotnet-runtime)
- [golang.Go](https://marketplace.visualstudio.com/items?itemName=golang.Go)
- [mikestead.dotenv](https://marketplace.visualstudio.com/items?itemName=mikestead.dotenv)
- [esbenp.prettier-vscode](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
- [GitHub.vscode-pull-request-github](https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-pull-request-github)
- [GitHub.codespaces](https://marketplace.visualstudio.com/items?itemName=GitHub.codespaces)
- [GitHub.copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot)
- [GitHub.remotehub](https://marketplace.visualstudio.com/items?itemName=GitHub.remotehub)
- [GitHub.vscode-codeql](https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-codeql)
- [ms-vscode.azure-account](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-account)
- [yzhang.markdown-all-in-one](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one)
- [cschleiden.vscode-github-actions](https://marketplace.visualstudio.com/items?itemName=cschleiden.vscode-github-actions)
- [ms-vscode-remote.vscode-remote-extensionpack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)
- [VisualStudioExptTeam.vscodeintellicode](https://marketplace.visualstudio.com/items?itemName=VisualStudioExptTeam.vscodeintellicode)
- [ms-vscode.powershell](https://marketplace.visualstudio.com/items?itemName=ms-vscode.powershell)
- [ms-vscode.azure-repos](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-repos)
- [azps-tools.azps-tools](https://marketplace.visualstudio.com/items?itemName=azps-tools.azps-tools)
- [ms-vscode.vscode-node-azure-pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-node-azure-pack)
- [eamodio.gitlens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens)
- [tfsec.tfsec](https://marketplace.visualstudio.com/items?itemName=tfsec.tfsec)
- [bierner.markdown-mermaid](https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid)

## Initial Setup

Under [IAC](./../IAC/), you can find the initial setup bash script. This script deploys required Azure Services for Symphony for development and testing:

- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry)
- [eShop Web docker image](https://github.com/dotnet-architecture/eShopOnWeb/tree/main/src/Web)
- [eShop API docker image](https://github.com/dotnet-architecture/eShopOnWeb/tree/main/src/PublicApi)

## Deploy

Each IAC configuration (Terraform and Bicep) contains `deploy.sh` script. This straightforward script allows you to run and test your code quickly.

## Input Variables

For local development experience, you can use predefined input variables files (_{env}_.tfvars.json for Terraform, parameters._{env}_.json for Bicep). Files contains hardcoded values. Feel free to adjust to your needs.
