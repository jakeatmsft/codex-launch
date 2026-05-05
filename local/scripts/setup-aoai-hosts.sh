#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

load_codex_local_env

domain="${AZURE_OPENAI_DOMAIN:-RESOURCE-NAME.openai.azure.com}"

if [ -z "${domain}" ]; then
  echo "AZURE_OPENAI_DOMAIN is empty. Set it in local/.env or .env." >&2
  exit 1
fi

ip=""
if command -v getent >/dev/null 2>&1; then
  ip="$(getent hosts "${domain}" | awk 'NR==1 {print $1}')"
fi

if [ -z "${ip}" ] && command -v dig >/dev/null 2>&1; then
  ip="$(dig +short "${domain}" | awk 'NF{print $1}' | tail -n1)"
fi

if [ -z "${ip}" ]; then
  echo "Could not resolve IP for ${domain}." >&2
  exit 1
fi

hosts_tmp="$(mktemp)"
awk -v d="${domain}" '
{
  keep = 1
  for (i = 2; i <= NF; i++) {
    if ($i == d) {
      keep = 0
      break
    }
  }
  if (keep) {
    print
  }
}
' /etc/hosts > "${hosts_tmp}"

echo "${ip} ${domain}" >> "${hosts_tmp}"
sudo cp "${hosts_tmp}" /etc/hosts
rm -f "${hosts_tmp}"

echo "Updated /etc/hosts with ${ip} ${domain}"
