# You can pick any Debian/Ubuntu-based image. 😊
ARG VARIANT=0-bullseye
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
    && apt-get install -y graphviz \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# [Option] Install Azure CLI
ARG INSTALL_AZURE_CLI="true"
# [Option] Install Azure Bicep
ARG INSTALL_AZURE_BICEP="true"
# [Option] Install Docker CLI
ARG INSTALL_DOCKER="true"
# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="none"
ENV NVM_DIR=/usr/local/share/nvm
ENV NVM_SYMLINK_CURRENT=true \
    PATH=${NVM_DIR}/current/bin:${PATH}
RUN if [ "${INSTALL_AZURE_CLI}" = "true" ]; then bash /tmp/library-scripts/azcli-debian.sh; fi \
    && if [ "${INSTALL_AZURE_BICEP}" = "true" ]; then curl -Lo /usr/local/bin/bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64 && chmod +x /usr/local/bin/bicep; fi \
    && if [ "${NODE_VERSION}" != "none" ]; then bash /tmp/library-scripts/node-debian.sh "${NVM_DIR}" "${NODE_VERSION}" "${USERNAME}"; fi \
    && if [ "${INSTALL_DOCKER}" = "true" ]; then \
        bash /tmp/library-scripts/docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}"; \
    else \
        echo '#!/bin/bash\n"$@"' > /usr/local/share/docker-init.sh && chmod +x /usr/local/share/docker-init.sh; \
    fi

# [Option] Install Go tools
# ARG INSTALL_GO="true"
# ENV GO111MODULE=auto
# RUN if [ "${INSTALL_GO}" = "true" ]; then bash /tmp/library-scripts/go-debian.sh "none" "/usr/local/go" "${GOPATH}" "${USERNAME}" "false"; fi

# Install Terraform, tflint, Terragrunt
ARG TERRAFORM_VERSION=1.1.7
ARG TFLINT_VERSION=0.34.1
ARG TERRAGRUNT_VERSION=0.36.3
RUN bash /tmp/library-scripts/terraform-debian.sh "${TERRAFORM_VERSION}" "${TFLINT_VERSION}" "${TERRAGRUNT_VERSION}" \
    && rm -rf /tmp/library-scripts

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# Cleanup
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts

ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]
