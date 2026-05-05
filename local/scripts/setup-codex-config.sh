#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

load_codex_local_env

endpoint="$(normalize_azure_openai_endpoint)"
model="${AZURE_OPENAI_DEPLOYMENT_NAME:-gpt-5-codex}"
api_version="${AZURE_OPENAI_API_VERSION:-2025-04-01-preview}"
reasoning_effort="${CODEX_MODEL_REASONING_EFFORT:-high}"
codex_home="$(default_codex_home)"
auth_command="${CODEX_AZURE_AUTH_COMMAND:-${codex_home}/bin/fetch-azure-openai-token.sh}"
auth_refresh_interval_ms="${CODEX_AZURE_AUTH_REFRESH_INTERVAL_MS:-300000}"
auth_timeout_ms="${CODEX_AZURE_AUTH_TIMEOUT_MS:-5000}"
azure_config_dir="$(default_azure_config_dir)"

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
name = "Azure OpenAI"
base_url = "${endpoint}/openai/v1"
query_params = { api-version = "${api_version}" }
wire_api = "responses"
model_reasoning_effort = "${reasoning_effort}"

[model_providers.azure.auth]
command = "${auth_command}"
refresh_interval_ms = ${auth_refresh_interval_ms}
timeout_ms = ${auth_timeout_ms}

CONFIG

echo "Installed Codex Azure auth helper to ${auth_command}"
echo "Wrote Codex config to ${config_file}"
