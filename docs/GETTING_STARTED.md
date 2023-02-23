# Create your own Symphony Repository and workflows

Symphony offers a CLI to provision all needed resources, and creates the code repository on the orchestrator of your choice. **Note : symphony commands are build specifically for use in a bash/zsh shell.**

## Symphony CLI commands

### Symphony provision cmd

This command deploys a set of azure resources and identities required by Symphony for the sample app, the workflows, and resource state management. It also creates a Symphony.json in ./.symphony/ to store the names of the deployed resources. Resources list below

| Resource           | Description                                                                                         | IaC tool|
| -----------        | --------------------------------------------------------------------------------------------------  | --------|
| Resource Group     | Container for all needed Symphony deployed resources.                                               | Terraform /Bicep|
| Key Vault          | Store the created identities secrets to be used by workflows.                                       | Terraform /Bicep|
| Container Registry | Stores the Symphony sample app 'eshop on web' docker images.                                        | Terraform /Bicep|
| Service Principal  | Reader Service principal used by the CI to access the Key Vault.                                    | Terraform /Bicep|
| Service Principal  | [Create/Bring your own] Owner Service Principal used to access the target azure subscription used to deploy by IaC modules. | Terraform /Bicep|
| Storage Account    | Storage account with containers to be used as terraform remote state backend.                       | Terraform|
| Storage Account    | Storage account with containers to store backup copies of terraform modules state files.            | Terraform|

### Symphony destroy cmd

This command deletes the previously deployed symphony resources form executing the `symphony provision` using the Symphony.json in ./.symphony/ folder. **Note : Configured Symphony Repository workflow can no longer run after the symphony resources are deleted.**

### Symphony pipeline config cmd

- This command creates and configure a Symphony code repository, workflow pipelines, workflow secrets, and push the code to the newly created repository on the selected orchestrator. It also creates set of json logs files in ./.symphony/logs/<YYYY-MM-DD-HH-MM-SS-ORCH> to store responses from all the orchestrator calls for easier debug. Configured resources below.

| Resource                      | Description                                                                                         | orchestrator tool   |
| ----------------------------- | --------------------------------------------------------------------------------------------------  | ------------------- |
| Symphony Code Repository      | an Azure DevOps or a GitHub code Repository based on the selected tool in cmd.                      | Azure devOps/GitHub |
| CI-Deploy main workflow       | an Azure devops pipeline or a GitHub action ,based on the selected tool in cmd, to deploy the IaC code .                      | Azure devOps/GitHub |
| CI-Destroy main workflow      | an Azure devops pipeline or a GitHub action ,based on the selected tool in cmd, to destroy a previously deployed environment using the CI-Deploy workflow. | Azure devOps/GitHub |
|AZURE_CREDENTIALS Secret       | GitHub Secret to store the Symphony **Reader Service Principal** credentials used by the Workflows to access the Symphony KeyVault | GitHub |
|Symphony-KV Service Connection | Azure DevOps ARM Service connection using **Reader Service Principal** credentials used by the pipelines to access the Symphony KeyVault | Azure DevOps |

## Prerequisites tools

- Install [Azure Cli](https://docs.microsoft.com/cli/azure).
- Install [JQ](https://stedolan.github.io/jq).

  For GitHub:
  - Install [GitHub Cli](https://docs.github.com/en/github-cli/github-cli/about-github-cli).
  - Create a [GitHub PAT](https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with **"admin:org" "read:org"** setting enabled on the organization to be used to provision Symphony.

  for AZure DevOps:
  - Create an [Azure DevOps PAT](https://learn.microsoft.com/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows) on the organization to be used to provision Symphony.

## Getting started

- Clone this repo.
- Login to AZ CLi `az login`
- Configure the symphony cli `source setup.sh`
- Deploy dependent resources `symphony provision`
- Deploy and Configure an orchestrator `symphony pipeline config <azdo|github> <terraform|bicep>`
