# You can pick any Debian/Ubuntu-based image. 😊
ARG VARIANT=bullseye
FROM mcr.microsoft.com/vscode/devcontainers/base:${VARIANT}

COPY library-scripts/*.sh /tmp/library-scripts/

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"
# [Option] Enable non-root Docker access in container
ARG ENABLE_NONROOT_DOCKER="true"
# [Option] Use the OSS Moby CLI instead of the licensed Docker CLI
ARG USE_MOBY="true"
# Enable new "BUILDKIT" mode for Docker CLI
ENV DOCKER_BUILDKIT=1

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    && apt-get install -y graphviz make

# [Option] Install Azure CLI
ARG INSTALL_AZURE_CLI="true"
ARG AZURE_CLI_VERSION=""
# [Option] Install Azure Bicep
ARG INSTALL_AZURE_BICEP="true"
ARG AZURE_BICEP_VERSION=""
# [Option] Install Docker CLI
ARG INSTALL_DOCKER="true"

ENV NVM_DIR=/usr/local/share/nvm
ENV NVM_SYMLINK_CURRENT=true \
    PATH=${NVM_DIR}/current/bin:${PATH}
RUN if [ "${INSTALL_AZURE_CLI}" = "true" ]; then bash /tmp/library-scripts/azcli-debian.sh "${AZURE_CLI_VERSION}"; fi \
    && if [ "${INSTALL_AZURE_BICEP}" = "true" ]; then AZURE_BICEP_VERSION=${AZURE_BICEP_VERSION:-"latest"} && curl -Lo /usr/local/bin/bicep https://github.com/Azure/bicep/releases/download/${AZURE_BICEP_VERSION}/bicep-linux-x64 && chmod +x /usr/local/bin/bicep; fi \
    && if [ "${INSTALL_DOCKER}" = "true" ]; then \
        bash /tmp/library-scripts/docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}"; \
    else \
        echo '#!/bin/bash\n"$@"' > /usr/local/share/docker-init.sh && chmod +x /usr/local/share/docker-init.sh; \
    fi

# [Option] Install Go tools
ARG INSTALL_GO="true"
ARG GO_VERSION=""
ENV GO111MODULE=auto
RUN if [ "${INSTALL_GO}" = "true" ]; then bash /tmp/library-scripts/go-debian.sh "${GO_VERSION}" "/usr/local/go" "${GOPATH}" "${USERNAME}" "true" \
    && export PATH=/usr/local/go/bin:${PATH} && chmod +x /usr/local/go/bin/go; fi

# Install Terraform, tflint, Terragrunt
ARG INSTALL_TERRAFORM="true"
ARG TERRAFORM_VERSION=""
ARG TFLINT_VERSION=""
ARG TERRAGRUNT_VERSION=""
RUN if [ "${INSTALL_TERRAFORM}" = "true" ]; then bash /tmp/library-scripts/terraform-debian.sh "${TERRAFORM_VERSION}" "${TFLINT_VERSION}" "${TERRAGRUNT_VERSION}"; fi

# # Install TFLint Azure RM Ruleset
ARG TFLINT_RULESET_AZURERM_VERSION=""
RUN if [ "${INSTALL_TERRAFORM}" = "true" ]; then curl -Lo ~/tflint-ruleset-azurerm.zip https://github.com/terraform-linters/tflint-ruleset-azurerm/releases/download/${TFLINT_RULESET_AZURERM_VERSION}/tflint-ruleset-azurerm_linux_amd64.zip \
    && mkdir -p ~/.tflint.d/plugins \
    && unzip ~/tflint-ruleset-azurerm.zip -d ~/.tflint.d/plugins \
    && mv ~/.tflint.d /home/vscode \
    && rm -f ~/tflint-ruleset-azurerm.zip; fi

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# Cleanup
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts

ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]
