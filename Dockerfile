# C:\CodexApp\Dockerfile
FROM node:22-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG AZURE_OPENAI_DOMAIN=RESOURCE-NAME.openai.azure.com
ARG AZURE_OPENAI_ENDPOINT=https://RESOURCE-NAME.openai.azure.com
ARG DOTNET_CHANNEL=8.0
ENV AZURE_OPENAI_DOMAIN=${AZURE_OPENAI_DOMAIN}
ENV AZURE_OPENAI_ENDPOINT=${AZURE_OPENAI_ENDPOINT}
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH="${DOTNET_ROOT}:${PATH}"

RUN apt-get update \
  && apt-get install -y --no-install-recommends dnsutils sudo curl ca-certificates python3 python3-pip gnupg lsb-release \
  && rm -rf /var/lib/apt/lists/*

# Install Azure CLI so DefaultAzureCredential can use AzureCliCredential with mounted ~/.azure
RUN mkdir -p /etc/apt/keyrings \
  && curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/microsoft.gpg \
  && chmod go+r /etc/apt/keyrings/microsoft.gpg \
  && AZ_REPO=$(lsb_release -cs) \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ ${AZ_REPO} main" > /etc/apt/sources.list.d/azure-cli.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends azure-cli \
  && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
  && chmod +x /tmp/dotnet-install.sh \
  && /tmp/dotnet-install.sh --channel ${DOTNET_CHANNEL} --install-dir ${DOTNET_ROOT} --quality ga \
  && ln -s ${DOTNET_ROOT}/dotnet /usr/local/bin/dotnet \
  && rm /tmp/dotnet-install.sh

# Install Azure Identity SDK for optional credential flows
RUN python3 -m pip install --no-cache-dir --break-system-packages azure-identity

# Install the Codex CLI globally
RUN npm install -g @openai/codex

# Provide a helper to open an interactive shell
RUN printf '#!/usr/bin/env bash\nexec /bin/bash "$@"\n' > /usr/local/bin/codex-shell \
  && chmod +x /usr/local/bin/codex-shell

# Extracted shell/runtime setup for containerized Codex.
COPY local/docker/codex-bashrc.sh /tmp/codex-bashrc.sh
RUN cat /tmp/codex-bashrc.sh >> /root/.bashrc \
  && rm /tmp/codex-bashrc.sh

# Set working dir inside container
WORKDIR /usr/src/app


# Default to bash for interactive use
CMD ["bash"]
