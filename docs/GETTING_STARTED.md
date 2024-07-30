# Create your own Symphony Repository and workflows

Symphony offers a CLI to perform several actions that bootstrap a new IAC project on the orchestrator of your choice. Symphony relies on several backing resources that are needed to facilitate deployment workflows/pipelines. These resources can be provisioned via the CLI and the tool can also create and configure the code repository.

> [!NOTE]
> Symphony commands are built specifically for use in a bash/zsh shell.

## Prerequisites tools

- Install [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

> [!NOTE]
> Make sure your git version is 2.40.0 or newer. Having an older git version can cause errors!

- Install [Azure CLI](https://docs.microsoft.com/cli/azure).

> [!NOTE]
> If you are using WSL on Windows, make sure to download [Azure CLI for Linux](https://learn.microsoft.com/cli/azure/install-azure-cli-linux) from WSL.
> The command `which az` should return the path `/usr/bin/az`.
> Using the Windows version of the Azure CLI from WSL can cause unexpected errors.

- Install [JQ](https://stedolan.github.io/jq).

  For GitHub:
  - Install [GitHub CLI](https://docs.github.com/en/github-cli/github-cli/about-github-cli).
  - Create a [GitHub PAT](https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with **"repo"**, **"workflow"**, **"admin:org"-"read:org"** settings enabled on the organization to be used to provision Symphony.
  - Symphony creates a new GitHub repository as part of the configuration process. If this repository is deployed to a GitHub Organization, please ensure that permissions for GITHUB_TOKEN are set to read and write.  This is needed to allow GitHub actions to successfully upload and publish IaC test results. Follow the **Configure the default GITHUB_TOKEN Permission** section on the following [GitHub Documentation post](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#setting-the-permissions-of-the-github_token-for-your-repository).
  - As part of the Symphony infrastructure deployment workflow, [GitLeaks](https://github.com/gitleaks/gitleaks) is run to check for any potentially leaked credentials. The results of the scan are saved in a **Sarif** report formatted document. To be able to publish the report for visualization and GitHub integration, your GitHub organization needs to have access to  **Advanced Security Features**. GitHub Advanced Security features are enabled for all public repositories on GitHub.com. If your Organization uses GitHub Enterprise Cloud with Advanced Security, and you plan to use Symphony with private or internal repositories, **Advanced Security Features** must be enabled. To read more about the availability of this feature please see  [The official GitHub Documentation for GitHub Advanced Security](https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security).

  For Azure DevOps:
  - Azure DevOps Services (Hosted)
    - Create an [Azure DevOps PAT](https://learn.microsoft.com/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows) on the organization to be used to provision Symphony.

    > **Note**: The `Azure DevOps PAT` must have the following permissions:
    >
    >| Description | Permission |
    >| ----------- | ----------- |
    >| Agent Pools | Read |
    >| Build | Read & Execute |
    >| Code | Read & Write |
    >| Connected Server | Connected Server |
    >| Pipeline Resources | Use and Manage |
    >| Project and Team | Read, Write & Manage |
    >| Release | Read, Write & Execute |
    >| Service Connections | Read, Query & Manage |

  - Azure DevOps Server:
    - Create an [Azure DevOps PAT](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops-2022&tabs=Windows) on the organization to be used to provision Symphony.

    > **Note**: The `Azure DevOps PAT` must have the following permissions:
    >
    >| Description | Permission |
    >| ----------- | ----------- |
    >| Agent Pools | Read |
    >| Build | Read & Execute |
    >| Code | Read & Write |
    >| Connected Server | Connected Server |
    >| Pipeline Resources | Use and Manage |
    >| Project and Team | Read, Write & Manage |
    >| Release | Read, Write & Execute |
    >| Service Connections | Read, Query & Manage |

    - An Agent Pool named `Default` is required for the `symphony pipeline` generated pipelines to run on the target server.  The Default agent pool must include at least one self hosted build agent.
    To deploy a new agent follow the instructions provided in in the [Azure Pipelines - Self-hosted Linux agents](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/linux-agent?view=azure-devops#download-and-configure-the-agent) walkthrough.

    - Ensure that the following dependencies are installed on the self hosted agent

      ```bash
      sudo apt update
      sudo apt install build-essential unzip
      ```

    - Self-hosted agents can be run in either:
      - A [docker container](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops).  When running a build agent container in [Azure Container Instance](https://learn.microsoft.com/en-us/azure/container-instances/), please ensure that the instance size is at least 2 core CPU and 7GB ram. This is required to run symphony pipelines.

      - A Linux or Windows VM, see [Getting started with Symphony on a Virtual Machine](./GETTING_STARTED_VM.md)

## Getting started

```bash
# Clone this repo.
$> git clone https://github.com/microsoft/symphony.git && cd symphony

# Login to AZ CLi
$> az login

# Ensure the target subscription is set
$> az account set --subscription <TargetSubscriptionId>

# Configure the symphony cli
$> source setup.sh

# Deploy dependent resources.
$> symphony provision

# Deploy and Configure an orchestrator.
$> symphony pipeline config <azdo|github> <terraform|bicep>
```

**Notes**:

- When naming the azdo project, during `symphony pipeline config`, ensure there are no spaces in the project name. Also, make sure the project name adheres to this [guideline](https://learn.microsoft.com/en-us/azure/devops/organizations/settings/naming-restrictions?view=azure-devops#project-names).
- Both AzDO PAAS service (`*.azure.com` or `*.visualstudio.com`) and server (`your-azdo-server.com`) are supported. The `ORG` name is used for the service and `Project Collection` name for server hosts. The terminal may prompt for AzDO Server login credentials if not accessible.

Now that you have completed the provisioning process. Go you created Symphony on the SCM you selected when you ran `Symphony pipeline config` command. You can browse the code, tests, and run the pipelines as well to deploy the sample app.

Also, take a look at the Symphony resources deployed when you ran the `Symphony provision` command. you can find the names of the resources in the ./.symphony/symphony.json

## Symphony CLI commands

### Symphony provision

```bash
$> symphony provision
```

This command deploys a set of Azure resources and identities required by Symphony for the sample app, Workflows, and managing the IaC resources state. It prompts input of a target Azure location to deploy the resources to.

It also creates a symphony.json in ./.symphony/ to store the names of the deployed resources.
The following resources will be deployed as dependencies for Symphony:

| Resource           | Description                                                                                                                 | IaC tool          |
|--------------------|-----------------------------------------------------------------------------------------------------------------------------|-------------------|
| Resource Group     | Container for all needed Symphony deployed resources.                                                                       | Terraform / Bicep |
| Key Vault          | Stores the credential secrets to be used by workflows.                                                                      | Terraform / Bicep |
| Container Registry | Stores the Symphony sample app 'eshop on web' docker images.                                                                | Terraform / Bicep |
| Service Principal  | Reader Service principal used by the CI to access the Key Vault.                                                            | Terraform / Bicep |
| Service Principal  | [Create/Bring your own] Owner Service Principal used to access the target azure subscription used to deploy by IaC modules. | Terraform / Bicep |
| Storage Account    | Storage account with Azure Blob Containers that are used for terraform remote state backend.                                | Terraform         |
| Storage Account    | Storage account with Azure Blob Containers that are used to store backup copies of terraform modules state files.           | Terraform         |

### Symphony Destroy

```bash
$> symphony destroy
```

This command deletes symphony resources that were deployed by executing the `symphony provision` command. It utilizes the symphony.json file in ./.symphony/ folder.

> [!NOTE]
> Configured Symphony Repository workflow can no longer run after the Symphony resources are deleted. You need to manually delete the code repo on the SCM.

### Symphony Pipeline Config

```bash
$> symphony pipeline config <orchestrator> <iac tool>
```

Example

```bash
$> symphony pipeline config github terraform
```

This command creates and configures a Symphony project that includes a code repository, workflow pipelines, and workflow secrets. It then pushes the code to the newly created repository on the selected scm provider. It also creates a set of JSON logs files in ./.symphony/logs/YYYY-MM-DD-HH-MM-SS-ORCH to store responses from all the orchestrator calls for easier debugging. The following resources will be Configured:

| Resource                       | Description                                                                                                                                                | orchestrator tool   |
|--------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------|
| Symphony Code Repository       | an Azure DevOps or a GitHub code Repository based on the selected tool in cmd.                                                                             | Azure devOps/GitHub |
| CI-Deploy main workflow        | an Azure devops pipeline or a GitHub action ,based on the selected tool in cmd, to deploy the IaC code .                                                   | Azure devOps/GitHub |
| CI-Destroy main workflow       | an Azure devops pipeline or a GitHub action ,based on the selected tool in cmd, to destroy a previously deployed environment using the CI-Deploy workflow. | Azure devOps/GitHub |
| AZURE_CREDENTIALS Secret       | GitHub Secret to store the Symphony **Reader Service Principal** credentials used by the Workflows to access the Symphony KeyVault                         | GitHub              |
| Symphony-KV Service Connection | Azure DevOps ARM Service connection using **Reader Service Principal** credentials used by the pipelines to access the Symphony KeyVault                   | Azure DevOps        |
