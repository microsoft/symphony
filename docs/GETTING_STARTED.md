# Create your own Symphony Repository and workflows

Symphony offers a CLI to perform several actions that bootstraps a new IAC project on the orchestrator of your choice. Symphony relies on several backing resources that are needed to facilitate deployment workflows/pipelines. These resources can be provisioned via the CLI and the tool can also create and configure the code repository.
**Note : symphony commands are build specifically for use in a bash/zsh shell.**

## Prerequisites tools

- Install [Azure Cli](https://docs.microsoft.com/cli/azure).
- Install [JQ](https://stedolan.github.io/jq).

  For GitHub:
  - Install [GitHub Cli](https://docs.github.com/en/github-cli/github-cli/about-github-cli).
  - Create a [GitHub PAT](https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with **"admin:org" "read:org"** setting enabled on the organization to be used to provision Symphony.
  - Ensure that [GitHub Cli](https://docs.github.com/en/github-cli/github-cli/about-github-cli) is logged out prior to running the `Symphony pipeline config` cmd.

  for Azure DevOps:
  - Create an [Azure DevOps PAT](https://learn.microsoft.com/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows) on the organization to be used to provision Symphony.

## Getting started

```bash
# Clone this repo.
$> git clone https://github.com/microsoft/symphony.git

# Login to AZ CLi 
$> az login

# Configure the symphony cli 
$> source setup.sh

# Deploy dependent resources.
$> symphony provision

# Deploy and Configure an orchestrator.
$> symphony pipeline config <azdo|github> <terraform|bicep>
```

## Symphony CLI commands

### Symphony provision

```bash
$> symphony provision
```

This command deploys following:

- A set of azure resources and identities required by Symphony for the sample app.
- Workflows, and resource state management.

It also creates a Symphony.json in ./.symphony/ to store the names of the deployed resources.
The following resources will be deployed as dependencies for Symphony:

| Resource           | Description                                                                                         | IaC tool|
| -----------        | --------------------------------------------------------------------------------------------------  | --------|
| Resource Group     | Container for all needed Symphony deployed resources.                                               | Terraform /Bicep|
| Key Vault          | Stores the credential secrets to be used by workflows.                                       | Terraform /Bicep|
| Container Registry | Stores the Symphony sample app 'eshop on web' docker images.                                        | Terraform /Bicep|
| Service Principal  | Reader Service principal used by the CI to access the Key Vault.                                    | Terraform /Bicep|
| Service Principal  | [Create/Bring your own] Owner Service Principal used to access the target azure subscription used to deploy by IaC modules. | Terraform /Bicep|
| Storage Account    | Storage account with Azure Blob Containers that are used for terraform remote state backend.                       | Terraform|
| Storage Account    | Storage account with Azure Blob Containers that are used to store backup copies of terraform modules state files.            | Terraform|

### Symphony Destroy

```bash
$> symphony destroy
```

This command deletes symphony resources that were deployed by executing the `symphony provision` command. It utilizes the Symphony.json file in ./.symphony/ folder.

**Note : Configured Symphony Repository workflow can no longer run after the symphony resources are deleted.**

### Symphony Pipeline Config

```bash
$> symphony pipeline config <orchestrator> <iac tool>
```

Example

```bash
$> symphony pipeline config github terraform
```

- This command creates and configures a Symphony project that includes a code repository, workflow pipelines, workflow secrets. It then pushes the code to the newly created repository on the selected scm provider. It also creates set of json logs files in ./.symphony/logs/YYYY-MM-DD-HH-MM-SS-ORCH to store responses from all the orchestrator calls for easier debug. The following resources will be Configured:.

| Resource                      | Description                                                                                         | orchestrator tool   |
| ----------------------------- | --------------------------------------------------------------------------------------------------  | ------------------- |
| Symphony Code Repository      | an Azure DevOps or a GitHub code Repository based on the selected tool in cmd.                      | Azure devOps/GitHub |
| CI-Deploy main workflow       | an Azure devops pipeline or a GitHub action ,based on the selected tool in cmd, to deploy the IaC code .                      | Azure devOps/GitHub |
| CI-Destroy main workflow      | an Azure devops pipeline or a GitHub action ,based on the selected tool in cmd, to destroy a previously deployed environment using the CI-Deploy workflow. | Azure devOps/GitHub |
|AZURE_CREDENTIALS Secret       | GitHub Secret to store the Symphony **Reader Service Principal** credentials used by the Workflows to access the Symphony KeyVault | GitHub |
|Symphony-KV Service Connection | Azure DevOps ARM Service connection using **Reader Service Principal** credentials used by the pipelines to access the Symphony KeyVault | Azure DevOps |
