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
  && apt-get install -y --no-install-recommends dnsutils sudo curl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
  && chmod +x /tmp/dotnet-install.sh \
  && /tmp/dotnet-install.sh --channel ${DOTNET_CHANNEL} --install-dir ${DOTNET_ROOT} --quality ga \
  && ln -s ${DOTNET_ROOT}/dotnet /usr/local/bin/dotnet \
  && rm /tmp/dotnet-install.sh

# Provide a helper to open an interactive shell
RUN printf '#!/usr/bin/env bash\nexec /bin/bash "$@"\n' > /usr/local/bin/codex-shell \
  && chmod +x /usr/local/bin/codex-shell

# Keep /etc/hosts synced with the Azure domain whenever a shell starts
RUN cat <<'EOF' >> /root/.bashrc
DOMAIN="${AZURE_OPENAI_DOMAIN:-RESOURCE-NAME.openai.azure.com}";
HOSTS_TMP=$(mktemp);
sudo sh -c "sed '/$DOMAIN/d' /etc/hosts > $HOSTS_TMP && cat $HOSTS_TMP > /etc/hosts";
rm -f "$HOSTS_TMP";
ip=$(dig +short $DOMAIN | grep -v '^$' | tail -n1);
[ -n "$ip" ] && echo "$ip $DOMAIN" | sudo tee -a /etc/hosts >/dev/null
EOF

# Load environment variables from project .env in interactive shells
RUN cat <<'EOF' >> /root/.bashrc
if [ -f /usr/src/app/.env ]; then
  set -a
  . /usr/src/app/.env
  set +a
fi
# Linux, macOS, or WSL
export AZURE_OPENAI_API_KEY="${AZURE_OPENAI_API_KEY:-}"
endpoint="${AZURE_OPENAI_ENDPOINT:-https://${AZURE_OPENAI_DOMAIN:-RESOURCE-NAME.openai.azure.com}}"
codex_model="${AZURE_OPENAI_DEPLOYMENT_NAME:-gpt-5-codex}"
mkdir -p ~/.codex
cat > ~/.codex/config.toml <<CONFIG
# Set the default model and provider
model = "${codex_model}"
model_provider = "azure"
preferred_auth_method = "apikey"

# Configure the Azure provider
[model_providers.azure]
name = "Azure"
base_url = "${endpoint}/openai"
env_key = "AZURE_OPENAI_API_KEY"
query_params = { api-version = "2025-04-01-preview" }
wire_api = "responses"
model_reasoning_effort = "high"

CONFIG
EOF

# Set working dir inside container
WORKDIR /usr/src/app

# Install the Codex CLI globally
RUN npm install -g @openai/codex

# Default to bash for interactive use
CMD ["bash"]
