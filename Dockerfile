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
export AZURE_CONFIG_DIR="${AZURE_CONFIG_DIR:-/root/.azure}"
export AZURE_OPENAI_API_KEY_FILE="${AZURE_OPENAI_API_KEY_FILE:-${AZURE_CONFIG_DIR}/aoai-access-token}"

_refresh_azure_openai_api_key_from_file() {
  local token_file="${AZURE_OPENAI_API_KEY_FILE:-}"
  [ -n "${token_file}" ] || return 1
  [ -r "${token_file}" ] || return 1

  local token
  token="$(tr -d '\r\n' < "${token_file}")"
  [ -n "${token}" ] || return 1
  export AZURE_OPENAI_API_KEY="${token}"
}

# Prefer token injection from host via mounted file.
_refresh_azure_openai_api_key_from_file >/dev/null 2>&1 || true

# Fallback for environments that only mount Azure CLI state.
if [ -z "${AZURE_OPENAI_API_KEY:-}" ] && command -v az >/dev/null 2>&1; then
  export AZURE_OPENAI_API_KEY="$(AZURE_CONFIG_DIR="${AZURE_CONFIG_DIR}" az account get-access-token --resource https://cognitiveservices.azure.com/ --query accessToken -o tsv 2>/dev/null || true)"
fi

# Re-read token file before each prompt so host-side refresh is picked up.
if [[ $- == *i* ]] && [ -z "${AOAI_TOKEN_PROMPT_HOOK_SET:-}" ]; then
  if [ -n "${PROMPT_COMMAND:-}" ]; then
    PROMPT_COMMAND="_refresh_azure_openai_api_key_from_file >/dev/null 2>&1 || true; ${PROMPT_COMMAND}"
  else
    PROMPT_COMMAND="_refresh_azure_openai_api_key_from_file >/dev/null 2>&1 || true"
  fi
  export AOAI_TOKEN_PROMPT_HOOK_SET=1
fi

# Ensure each codex invocation uses the latest host-refreshed token.
codex() {
  _refresh_azure_openai_api_key_from_file >/dev/null 2>&1 || true
  command codex "$@"
}

echo "[bashrc] AZURE_OPENAI_API_KEY set (len=${#AZURE_OPENAI_API_KEY})"

[ "$PWD" = "$HOME" ] && cd /mnt/c
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


# Default to bash for interactive use
CMD ["bash"]
