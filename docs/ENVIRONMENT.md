# Symphony Environment

An environment in Symphony is represented by a set of configuration files, each represents the input values for the IAC modules used, and set of credentials used to authenticate to the cloud related environment subscription at which resources are deployed.

![Workflow steps](./images/environment.PNG)

## Environment resources configurations

Environment resources configurations are files that stores input values used by IAC modules to configure the resources. There are different file formats to consider based on the IAC tool used e.g., Terraform vs Bicep vs Arm. For terraform .tfvars, json files can be used to pass values to the IAC modules while in Bicep Json files are the only available option. Thus a common format for all could be using JSON files to pass the input values to all.

IAC modules resources might need different configuration values based on the environment type. Resources configurations used for development purposes might use less tiers/capabilities compared to production environment resources to maintain cost. Hence the need to store resources configurations per environment in files as part of the code repos. This will also provide changes trackability like any through the used source control tool.

## Environment cloud configurations

Environment cloud configurations are credentials used to authenticate to the cloud environment's subscription at which resources are deployed. Those environment configurations are stored at the orchestrator tool. They are used by the IAC CI/CD pipelines for the deployments.

### Implementations options

There are multiple options to consider when storing the environment cloud configurations. While values can be stored as service connections, and secrets in the orchestrator tool directly, It can also be stored in a central azure key vault and have give the pipelines access to it.

| **Option**                 | **Azure Key vault**                                                                                                                                            | **Orchestrators Secrets/SVC**                                                              |
|----------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------|
| **Implementation details** | Central key vault contains secrets representing each env needed keys, sp, and ids                                                                              | Collection of secrets/config per env stored in the orchestrator tool                       |
| **Pro(s)**                 | - Central storage for all env secrets, easier to maintain, rotate and recover in case of leak or breach.<br />- No Credentials stored at the orchestrator tools. | - No added cost.                                                                           |
| **Con(s)**                 | - Added cost.                                                                                                                                                  | - Lists of secrets permanently stored in orchestrators are harder to maintain, and rotate. |

## Adding a new environment

To add a new environment to Symphony, you need to add the cofing json files representing that env details to the env section in the code repo, and add the needed cloud subscription details/secrets to the orchestrator tool.

## Code propagation across environments

TBD
