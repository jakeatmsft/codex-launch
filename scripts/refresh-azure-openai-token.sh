#!/usr/bin/env bash
set -euo pipefail

TOKEN_SCOPE="${AZURE_AI_TOKEN_SCOPE:-https://ai.azure.com/.default}"
AZURE_CONFIG_DIR="${AZURE_CONFIG_DIR:-$HOME/.azure-for-docker}"
TOKEN_FILE="${AZURE_OPENAI_TOKEN_FILE:-$AZURE_CONFIG_DIR/aoai-access-token}"

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI is required on the host machine." >&2
  exit 1
fi

if [ ! -d "${AZURE_CONFIG_DIR}" ]; then
  echo "AZURE_CONFIG_DIR does not exist: ${AZURE_CONFIG_DIR}" >&2
  echo "Create it and login first, for example:" >&2
  echo "  AZURE_CONFIG_DIR='${AZURE_CONFIG_DIR}' az login" >&2
  exit 1
fi

token="$(AZURE_CONFIG_DIR="${AZURE_CONFIG_DIR}" az account get-access-token --scope "${TOKEN_SCOPE}" --query accessToken -o tsv)"
expires_on="$(AZURE_CONFIG_DIR="${AZURE_CONFIG_DIR}" az account get-access-token --scope "${TOKEN_SCOPE}" --query expiresOn -o tsv)"

if [ -z "${token}" ]; then
  echo "Failed to retrieve access token from Azure CLI." >&2
  exit 1
fi

mkdir -p "$(dirname "${TOKEN_FILE}")"
printf '%s\n' "${token}" > "${TOKEN_FILE}"
chmod 600 "${TOKEN_FILE}"

echo "Wrote token to ${TOKEN_FILE}"
echo "Token expires at ${expires_on}"
