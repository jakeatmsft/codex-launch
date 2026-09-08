#!/usr/bin/env bash
set -euo pipefail

endpoint="${AZURE_OPENAI_ENDPOINT:-https://${AZURE_OPENAI_DOMAIN:-}}"
endpoint="${endpoint%/}"
model="${AZURE_OPENAI_DEPLOYMENT_NAME:-}"
api_version="${AZURE_OPENAI_API_VERSION:-2025-04-01-preview}"
reasoning_effort="${CODEX_MODEL_REASONING_EFFORT:-high}"
refresh_interval_ms="${CODEX_AZURE_AUTH_REFRESH_INTERVAL_MS:-300000}"
timeout_ms="${CODEX_AZURE_AUTH_TIMEOUT_MS:-5000}"
codex_home="${CODEX_HOME:-$HOME/.codex}"
config_file="${codex_home}/config.toml"
auth_command="/usr/local/bin/fetch-azure-openai-token.sh"

if [ -z "${endpoint}" ] || [[ "${endpoint}" == *RESOURCE-NAME* ]]; then
  echo "Set AZURE_OPENAI_ENDPOINT or AZURE_OPENAI_DOMAIN before starting the container." >&2
  exit 1
fi

if [ -z "${model}" ] || [ "${model}" = "your_deployment_name_here" ]; then
  echo "Set AZURE_OPENAI_DEPLOYMENT_NAME before starting the container." >&2
  exit 1
fi

mkdir -p "${codex_home}"

cat > "${config_file}" <<CONFIG
# Set the default model and provider
model = "${model}"
model_provider = "azure"

# Configure the Azure provider
[model_providers.azure]
name = "Azure OpenAI"
base_url = "${endpoint}/openai/v1"
query_params = { api-version = "${api_version}" }
wire_api = "responses"
model_reasoning_effort = "${reasoning_effort}"

[model_providers.azure.auth]
command = "${auth_command}"
refresh_interval_ms = ${refresh_interval_ms}
timeout_ms = ${timeout_ms}

CONFIG

if [ "$#" -eq 0 ]; then
  set -- bash
fi

exec "$@"
