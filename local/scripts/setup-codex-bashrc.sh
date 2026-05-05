#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

BASHRC_FILE="${BASHRC_FILE:-$HOME/.bashrc}"
CODEX_LAUNCH_DIR="${CODEX_LAUNCH_DIR:-${CODEX_LOCAL_REPO_ROOT}}"
ENV_SCRIPT="${CODEX_LAUNCH_DIR}/local/scripts/codex-local-env.sh"
HOSTS_SCRIPT="${CODEX_LAUNCH_DIR}/local/scripts/setup-aoai-hosts.sh"

MARKER_BEGIN="# >>> codex-launch local setup >>>"
MARKER_END="# <<< codex-launch local setup <<<"

touch "${BASHRC_FILE}"

cleaned_bashrc="$(mktemp)"

awk -v begin="${MARKER_BEGIN}" -v end="${MARKER_END}" '
$0 == begin { in_block = 1; next }
$0 == end { in_block = 0; next }
!in_block { print }
' "${BASHRC_FILE}" > "${cleaned_bashrc}"

{
  cat "${cleaned_bashrc}"
  cat <<BLOCK

${MARKER_BEGIN}
export AZURE_CONFIG_DIR="\${AZURE_CONFIG_DIR:-\$HOME/.azure-for-codex}"
CODEX_LAUNCH_DIR="${CODEX_LAUNCH_DIR}"

if [ -f "${ENV_SCRIPT}" ]; then
  source "${ENV_SCRIPT}"
fi

codex_local_hosts_sync() {
  "${HOSTS_SCRIPT}"
}
${MARKER_END}
BLOCK
} > "${BASHRC_FILE}"

rm -f "${cleaned_bashrc}"

echo "Updated ${BASHRC_FILE} with codex-launch local setup block"
