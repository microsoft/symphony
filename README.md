# Symphony

Symphony is a framework, set of patterns, and best practices for developing, testing, and deploying infrastructure on Azure using Infrastructure as Code (IAC). It includes modern DevOps practices for IAC, such as Main and Pull Request workflows, IaC Code Validation and Lining, Automated Testing, Security Scanning, Multi-environment deployments, module dependencies, and more.

It is an enterprise-level CI/CD multi-orchestrator, a multi-IaC framework that encapsulates best practices and guidelines for developing, testing, and deploying infrastructure as code, allowing you to prepare for and deploy to production quickly.

Symphony supports the following IAC tools:

- Terraform
- Bicep

Symphony supports the following Build Orchestrators:

- Azure DevOps
- GitHub

## Why use Symphony

Symphony offers the workflows needed to implement IaC automation. Symphony provides multi-environment support and can be used on both public and non-public clouds. With the easily pluggable and integrable workflow design, it integrates more tools with no need to update the workflow or change the CI/CD pipeline. Symphony offers all these features and more.

| Feature                      | Description                                                                                                                                                                 |
|------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Security Scanning            | Symphony helps prevent credential leaking in the IAC code by running security scanners in the workflows.                                                                 |
| Linting & Validation         | Symphony ensures no invalid IaC code early and reduces the development iteration loop.                                                                                      |
| IaC Modules Dependency       | Symphony offers a clear structure to organize modules based on dependency while allowing for the flexibility of automatically passing outputs from one module to the next. |
| Modules & End-to-end testing | Symphony provides samples to write, execute, and report on module tests and end-to-end tests for the IaC modules.                                                          |
| Multi Environment support    | Symphony offers a clear pattern to store different IaC module configurations per environment, allowing the workflows to swap configs based on the target environments           |

## Getting Started

Follow step-by-step instructions in the [Getting Started Document](./docs/GETTING_STARTED.md)

## Symphony Workflows

A mature workflow for IAC not only automates the deployment of the IAC resources but also incorporates engineering fundamentals, resources validation, dependency management, test execution, security scanning, and more. Symphony offers multiple workflows to ensure engineering excellence at every stage of the IaC process. Find more in the [Symphony Workflows Document](./docs/WORKFLOW.md).

## Symphony Environment

An environment in Symphony is represented by a set of configuration files, each representing the input values for the IAC modules used and a set of credentials used to authenticate to the cloud-related environment subscription at which resources are deployed. Find more about it in the [Symphony Environments Document](./docs/ENVIRONMENT.md)

## Symphony Testing

Symphony offers samples to write and execute both modules and end-to-end tests for the IaC module code and how the tests are integrated into the symphony workflows. Find more in the [Symphony Testing Document](./docs/TESTING.md)

## Contributing

Contributions to the project are welcome! Please follow [Contributing Guide](CONTRIBUTING.md).

## License

This project is under an [MIT License](LICENSE).

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos is subject to those third-party's policies.
