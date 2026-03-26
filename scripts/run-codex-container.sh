#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REFRESH_SCRIPT="${SCRIPT_DIR}/refresh-azure-openai-token.sh"

AZURE_CONFIG_DIR="${AZURE_CONFIG_DIR:-$HOME/.azure-for-docker}"
BUILD_IMAGE=1
RUN_ARGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-build)
      BUILD_IMAGE=0
      ;;
    --help|-h)
      cat <<'USAGE'
Usage: ./scripts/run-codex-container.sh [--no-build] [-- <container command args>]

Examples:
  ./scripts/run-codex-container.sh
  ./scripts/run-codex-container.sh --no-build
  ./scripts/run-codex-container.sh -- codex "Explain my repo"
  ./scripts/run-codex-container.sh -- /bin/bash
USAGE
      exit 0
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        RUN_ARGS+=("$1")
        shift
      done
      break
      ;;
    *)
      RUN_ARGS+=("$1")
      ;;
  esac
  shift
done

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI ('az') is required on the host." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required on the host." >&2
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
else
  echo "Neither 'docker compose' nor 'docker-compose' is available." >&2
  exit 1
fi

if [ ! -f "${REFRESH_SCRIPT}" ]; then
  echo "Missing refresh script: ${REFRESH_SCRIPT}" >&2
  exit 1
fi

mkdir -p "${AZURE_CONFIG_DIR}"

if ! AZURE_CONFIG_DIR="${AZURE_CONFIG_DIR}" az account show >/dev/null 2>&1; then
  echo "No Azure login found in ${AZURE_CONFIG_DIR}. Starting interactive login..."
  AZURE_CONFIG_DIR="${AZURE_CONFIG_DIR}" az login
fi

AZURE_CONFIG_DIR="${AZURE_CONFIG_DIR}" "${REFRESH_SCRIPT}"

cd "${REPO_ROOT}"

if [ "${BUILD_IMAGE}" = "1" ]; then
  "${COMPOSE_CMD[@]}" build
fi

if [ "${#RUN_ARGS[@]}" -gt 0 ]; then
  "${COMPOSE_CMD[@]}" run --rm codex "${RUN_ARGS[@]}"
else
  "${COMPOSE_CMD[@]}" run --rm codex
fi
