#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

load_codex_local_env

endpoint="$(normalize_foundry_project_endpoint)"
model="${AZURE_OPENAI_MODEL:-gpt-5.6-sol}"
reasoning_effort="${CODEX_MODEL_REASONING_EFFORT:-high}"
codex_home="$(default_codex_home)"
auth_command="${CODEX_AZURE_AUTH_COMMAND:-${codex_home}/bin/fetch-azure-openai-token.sh}"
auth_refresh_interval_ms="${CODEX_AZURE_AUTH_REFRESH_INTERVAL_MS:-300000}"
auth_timeout_ms="${CODEX_AZURE_AUTH_TIMEOUT_MS:-5000}"
azure_config_dir="$(default_azure_config_dir)"

if [ -z "${endpoint}" ] || [[ "${endpoint}" == *RESOURCE-NAME* ]] || [[ "${endpoint}" == *PROJECT-NAME* ]] || [[ "${endpoint}" != */api/projects/* ]]; then
  echo "Set AZURE_AI_PROJECT_ENDPOINT to a Foundry project endpoint containing /api/projects/PROJECT-NAME." >&2
  exit 1
fi

config_dir="${CODEX_CONFIG_DIR:-${codex_home}}"
config_file="${config_dir}/config.toml"
mkdir -p "${config_dir}"

install_codex_auth_helper "${auth_command}"
ensure_azure_config_dir "${azure_config_dir}"

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
# Refresh the Azure CLI token every five minutes.
refresh_interval_ms = ${auth_refresh_interval_ms}
timeout_ms = ${auth_timeout_ms}

CONFIG

echo "Installed Codex Azure auth helper to ${auth_command}"
echo "Wrote Codex config to ${config_file}"
