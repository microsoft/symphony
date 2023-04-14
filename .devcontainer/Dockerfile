# You can pick any Debian/Ubuntu-based image. 😊
FROM mcr.microsoft.com/vscode/devcontainers/base:bullseye

COPY library-scripts/*.sh /tmp/library-scripts/

# [Option] Enable non-root Docker access in container
ARG ENABLE_NONROOT_DOCKER="true"
# Enable new "BUILDKIT" mode for Docker CLI
ENV DOCKER_BUILDKIT=1

# [Option] Install Docker CLI
ARG INSTALL_DOCKER="true"

ENV NVM_DIR=/usr/local/share/nvm
ENV NVM_SYMLINK_CURRENT=true \
    PATH=${NVM_DIR}/current/bin:${PATH}
RUN if [ "${INSTALL_DOCKER}" = "true" ]; then \
        bash /tmp/library-scripts/docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}"; \
    else \
        echo '#!/bin/bash\n"$@"' > /usr/local/share/docker-init.sh && chmod +x /usr/local/share/docker-init.sh; \
    fi

# # Install TFLint Azure RM Ruleset
ARG INSTALL_TERRAFORM="true"
ARG TFLINT_RULESET_AZURERM_VERSION=""
RUN if [ "${INSTALL_TERRAFORM}" = "true" ]; then curl -Lo ~/tflint-ruleset-azurerm.zip https://github.com/terraform-linters/tflint-ruleset-azurerm/releases/download/${TFLINT_RULESET_AZURERM_VERSION}/tflint-ruleset-azurerm_linux_amd64.zip \
    && mkdir -p ~/.tflint.d/plugins \
    && unzip ~/tflint-ruleset-azurerm.zip -d ~/.tflint.d/plugins \
    && mv ~/.tflint.d /home/vscode \
    && rm -f ~/tflint-ruleset-azurerm.zip; fi

# [Optional] Uncomment this section to install additional OS packages.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends graphviz make

# Cleanup
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts

ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]
