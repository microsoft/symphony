# Symphony

Symphony is a framework and set of patterns and best practices for deploying infrastructure on Azure using Infrastructure as Code (IAC.)

Symphony supports the following IAC tools:

- Terraform
- Bicep

Symphony supports the following Build Orchestrators:

- Azure DevOps
- GitHub

## Getting Started

Note symphony's local bootstrapping was build specifically for use in a bash/zsh shell.

- Clone this repo.
- Configure the symphony cli `source setup.sh`
- Deploy dependent resources `symphony provision`
  - note: this only needs to be run once.
- Deploy and Configure an orchestrator:
  - `symphony pipeline config <azdo|github> <terraform|bicep>`

## Docs

- [Workflow](./docs/WORKFLOW.md)
- [Environments](./docs/ENVIRONMENT.md)
  
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
