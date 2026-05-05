#!/usr/bin/env bash
set -euo pipefail

export AZURE_CONFIG_DIR="${AZURE_CONFIG_DIR:-$HOME/.azure-for-codex}"
resource="${AZURE_OPENAI_TOKEN_RESOURCE:-https://cognitiveservices.azure.com/}"

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI not found: az" >&2
  exit 1
fi

exec env AZURE_CONFIG_DIR="${AZURE_CONFIG_DIR}" \
  az account get-access-token \
    --resource "${resource}" \
    --query accessToken \
    -o tsv
