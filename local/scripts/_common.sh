#!/usr/bin/env bash
# shellcheck shell=bash

CODEX_LOCAL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_LOCAL_DIR="$(cd "${CODEX_LOCAL_SCRIPT_DIR}/.." && pwd)"
CODEX_LOCAL_REPO_ROOT="$(cd "${CODEX_LOCAL_DIR}/.." && pwd)"

load_env_file() {
  local env_file="$1"
  if [ -f "${env_file}" ]; then
    set -a
    # shellcheck disable=SC1090
    . "${env_file}"
    set +a
  fi
}

load_codex_local_env() {
  local -a explicit_names=()
  local -a explicit_values=()
  local name index

  # Explicit command-line environment values take precedence over both files.
  for name in \
    AZURE_OPENAI_DOMAIN \
    AZURE_OPENAI_ENDPOINT \
    AZURE_OPENAI_DEPLOYMENT_NAME \
    AZURE_OPENAI_API_VERSION \
    AZURE_OPENAI_TOKEN_RESOURCE \
    CODEX_MODEL_REASONING_EFFORT \
    CODEX_AZURE_AUTH_COMMAND \
    CODEX_AZURE_AUTH_REFRESH_INTERVAL_MS \
    CODEX_AZURE_AUTH_TIMEOUT_MS; do
    if [[ -v "${name}" ]]; then
      explicit_names+=("${name}")
      explicit_values+=("${!name}")
    fi
  done

  load_env_file "${CODEX_LOCAL_REPO_ROOT}/.env"
  load_env_file "${CODEX_LOCAL_DIR}/.env"

  for ((index = 0; index < ${#explicit_names[@]}; index++)); do
    export "${explicit_names[index]}=${explicit_values[index]}"
  done
}

default_codex_home() {
  printf '%s\n' "${CODEX_HOME:-${CODEX_CONFIG_DIR:-$HOME/.codex}}"
}

default_azure_config_dir() {
  printf '%s\n' "${AZURE_CONFIG_DIR:-$HOME/.azure-for-codex}"
}

normalize_azure_openai_endpoint() {
  local domain endpoint
  domain="${AZURE_OPENAI_DOMAIN:-RESOURCE-NAME.openai.azure.com}"
  endpoint="${AZURE_OPENAI_ENDPOINT:-https://${domain}}"

  if [[ "${endpoint}" != http://* && "${endpoint}" != https://* ]]; then
    endpoint="https://${endpoint}"
  fi

  printf '%s\n' "${endpoint%/}"
}

install_codex_auth_helper() {
  local target_path="$1"
  local source_path="${CODEX_LOCAL_SCRIPT_DIR}/fetch-azure-openai-token.sh"

  if [ "${target_path}" = "${source_path}" ]; then
    chmod 755 "${source_path}"
    return 0
  fi

  mkdir -p "$(dirname "${target_path}")"
  install -m 755 "${source_path}" "${target_path}"
}

ensure_azure_config_dir() {
  local azure_config_dir="$1"
  local default_azure_config_dir="${HOME}/.azure"

  if [ -e "${azure_config_dir}" ]; then
    return 0
  fi

  if [ "${azure_config_dir}" = "$HOME/.azure-for-codex" ] && [ -e "${default_azure_config_dir}" ]; then
    ln -s "${default_azure_config_dir}" "${azure_config_dir}"
    echo "Linked ${azure_config_dir} -> ${default_azure_config_dir}"
    return 0
  fi

  echo "Azure config dir ${azure_config_dir} does not exist yet. Create it with: AZURE_CONFIG_DIR=\"${azure_config_dir}\" az login"
}
