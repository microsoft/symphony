# Project Lucidity

---

Project Lucidity allows you to easily deploy infrastructure to [Azure](https://azure.microsoft.com/en-us/) using [Terraform.](https://www.terraform.io/) The template enables you to easily create a new Azure DevOps project.

As part of the instlattion, the following will be automatically generated:

A new Azure Devops Project in your desired organisation which includes:

* A Terraform-Code repository populated with a sample application and terraform code to deploy this app.
* A Terraform-Pipelines repository populated with the Azure Pipelines yaml needed to deploy to multiple environments, perform environment tear-down and also a pull request workflow.
* Azure Pipelines used to deploy environments, teardown environments and handle pull requests.
* Variable Groups used by various pipelines.

---

## Terraform-Code Repo

This repository contains the code and tests needed to deploy an application using Project Lucidity.

The following folders are included, by default, with a new Lucidity install:

* _apps_: This contains a canonical sample application that can be used to test deployment. For larger workloads, it's recommended to store application code in a seperate repository within the same project.

* _environments_: This folder is used to store environment variables that are included in pipelines and shouldbe used for [Terraform Input Variables.](https://www.terraform.io/docs/configuration/variables.html#environment-variables), although any environment variable will be loaded.

The environment variables are under subfolders matching a specific environment and layer (dev, pr, prod etc). There exists a compile.env pipline that will combine all environment variables in a single environment into a `{environment}.compiled.env` file and stored as a secure file in Azure DevOps.

* _terraform_: This folder contains the Terraform code used to deploy your infrastructure. The terraform folder contains subfolders for each layer. Layers are a mechanism to seperate infrastructure based on it's function and specifies an order of precedence. Please see the [following document for further details on layers and the corresponding folder structure.](https://dev.azure.com/csedevops/terraform-template-public/_git/Terraform-Pipelines?path=%2Fdocs%2FDIRECTORYSTRUCTURE.md&_a=preview)

* _test_: Go tests for your terraform code.

* _scripts_: Utility scripts used by the project. Currently the folder contains scripts needed to compile env files into a single `{environment}.compiled.env` file.

---

## LICENSE

This project is under an [MIT License.](./LICENSE)

---

## Microsoft Open Source Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

Resources:

* [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
* [Microsoft Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
* Contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with questions or concerns
