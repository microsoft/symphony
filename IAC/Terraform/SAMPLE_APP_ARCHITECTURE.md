# Sample App Architecture

This repo has the following components to deploy the sample app using Symphony;

- [Official eShopOnWeb project](./apps/eShopOnWeb/)
- Sql Server Database
- [Symphony layers (Terraform modules) to deploy web app and database](./terraform/)
- [Tests written in golang to test symphony layers](./test)
- [DevContainer to develop symphony layers, also used in the CI/CD pipelines](./devcontainer)
- CI/CD pipelines

## DevContainer

[DevContainer configuration](./.devcontainer/devcontainer.json) uses [Dockerfile](./.devcontainer/Dockerfile) to build the _DevContainer_.

_DevContainer_ image is based on _Ubuntu:focal_ image and has the following packages installed;

