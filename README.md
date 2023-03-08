# Symphony

Symphony is a framework and set a of patterns and best practices for developing, testing, and deploying infrastructure on Azure using Infrastructure as Code (IAC.) It includes modern DevOps practices for IAC  such as Main and Pull Request workflows , IaC Code Validation & Linting, Automated Testing, Security Scanning, Multi-environment deployments, modules dependencies and more.

It is an enterprise level CI/CD multi-orchestrator, multi-IaC framework that encapsulates those best practices and guidance for developing, testing, and deploying infrastructure as code to host large scale solutions and get you production ready in no time.

Symphony supports the following IAC tools:

- Terraform
- Bicep

Symphony supports the following Build Orchestrators:

- Azure DevOps
- GitHub

## Why use Symphony

Symphony offers the workflows needed to implement IaC automation. Symphony provides multi-environment support, and can be used on both public and non-public cloud. With the easily plugable and integrable workflow design to integrate more tools with no need to update the workflow or change the CI/CD pipeline. Symphony offers all theses feature and more.

| Feature            | Description                                                                                            |
| ------------------ | ------------------------------------------------------------------------------------------------------ |
| Security Scanning | Symphony helps preventing credential leaking in the IAC code by running security scanners in the workflows. |
| Linting & Validation | Symphony ensures no invalid IaC code early and reduces the development iteration loop. |
| IaC Modules Dependency | Symphony offers a clear structure to organize modules based on dependency, while allowing for the flexibility of automatically passing outputs from one module to the next. |
|Modules & End to end testing | Symphony  provides samples to write, execute, and report on module tests and end to end tests for the IaC modules. |
| Multi Environment support | Symphony offers a clear pattern to store different IaC modules configurations per environment allowing the workflows can swap configs based on target environment |

## Getting Started

Follow step by step instructions in the [Getting Started Document](./docs/GETTING_STARTED.md)

## Symphony Workflows

A mature workflow for IAC not only automates the deployment of the IAC resources but also incorporates engineering fundamentals, resources validation, dependency management, test execution, security scanning, and more. Symphony offers multiple workflows to ensure engineering excellence at every stage of the IaC process. Find more in the [Symphony Workflows Document](./docs/WORKFLOW.md).

## Symphony Environment

An environment in Symphony is represented by a set of configuration files, each represents the input values for the IAC modules used, and set of credentials used to authenticate to the cloud related environment subscription at which resources are deployed. Find more about it in the [Symphony Environments Document](./docs/ENVIRONMENT.md)

## Symphony Testing

Symphony offers samples to write and execute both modules and end to end tests for the IaC module code and how the tests are integrated into the symphony workflows. Find more in the [Symphony Testing Document](./docs/TESTING.md)
  
## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit [Microsoft Contributor License Agreement](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## License

This project is under an [MIT License](LICENSE).

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
