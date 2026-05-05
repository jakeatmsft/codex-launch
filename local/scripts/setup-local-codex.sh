#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/setup-codex-config.sh"
"${SCRIPT_DIR}/setup-codex-bashrc.sh"
"${SCRIPT_DIR}/setup-aoai-hosts.sh"

echo "Local Codex setup complete. Run: source ~/.bashrc"
