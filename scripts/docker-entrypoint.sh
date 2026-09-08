#!/usr/bin/env bash
set -euo pipefail

endpoint="${AZURE_AI_PROJECT_ENDPOINT:-}"
endpoint="${endpoint%/}"
if [ -n "${endpoint}" ] && [[ "${endpoint}" != http://* && "${endpoint}" != https://* ]]; then
  endpoint="https://${endpoint}"
fi
model="${AZURE_OPENAI_MODEL:-gpt-5.6-sol}"
reasoning_effort="${CODEX_MODEL_REASONING_EFFORT:-high}"
refresh_interval_ms="${CODEX_AZURE_AUTH_REFRESH_INTERVAL_MS:-300000}"
timeout_ms="${CODEX_AZURE_AUTH_TIMEOUT_MS:-5000}"
codex_home="${CODEX_HOME:-$HOME/.codex}"
config_file="${codex_home}/config.toml"
auth_command="/usr/local/bin/fetch-azure-openai-token.sh"

if [ -z "${endpoint}" ] || [[ "${endpoint}" == *RESOURCE-NAME* ]] || [[ "${endpoint}" == *PROJECT-NAME* ]]; then
  echo "Set AZURE_AI_PROJECT_ENDPOINT before starting the container." >&2
  exit 1
fi

if [[ "${endpoint}" != */api/projects/* ]]; then
  echo "AZURE_AI_PROJECT_ENDPOINT must include /api/projects/PROJECT-NAME." >&2
  exit 1
fi

mkdir -p "${codex_home}"

cat > "${config_file}" <<CONFIG
# Set the default model and provider
model = "${model}"
model_provider = "azure"

# Configure the Azure provider
[model_providers.azure]
name = "Microsoft Foundry"
base_url = "${endpoint}/openai/v1"
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
