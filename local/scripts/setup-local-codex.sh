#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./_common.sh
source "${SCRIPT_DIR}/_common.sh"

load_codex_local_env

project_endpoint="$(normalize_foundry_project_endpoint)"

if [ -z "${project_endpoint}" ] || [[ "${project_endpoint}" == *RESOURCE-NAME* ]] || [[ "${project_endpoint}" == *PROJECT-NAME* ]]; then
  echo "Set AZURE_AI_PROJECT_ENDPOINT to your Microsoft Foundry project endpoint." >&2
  exit 1
fi

if [[ "${project_endpoint}" != */api/projects/* ]]; then
  echo "AZURE_AI_PROJECT_ENDPOINT must include /api/projects/PROJECT-NAME." >&2
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI ('az') is required." >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  if ! command -v npm >/dev/null 2>&1; then
    echo "Node.js and npm are required to install Codex." >&2
    exit 1
  fi

  echo "Installing the Codex CLI..."
  npm install -g @openai/codex
fi

azure_config_dir="$(default_azure_config_dir)"
ensure_azure_config_dir "${azure_config_dir}"
mkdir -p "${azure_config_dir}"
export AZURE_CONFIG_DIR="${azure_config_dir}"

if ! az account show >/dev/null 2>&1; then
  echo "No Azure login found in ${AZURE_CONFIG_DIR}. Starting interactive login..."
  az login
fi

"${SCRIPT_DIR}/setup-codex-config.sh"
"${SCRIPT_DIR}/setup-codex-bashrc.sh"
"${SCRIPT_DIR}/setup-aoai-hosts.sh"

echo "Local Codex setup complete. You can now run: codex"
