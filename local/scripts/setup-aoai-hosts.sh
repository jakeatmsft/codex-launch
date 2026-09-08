#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

load_codex_local_env

domain="$(foundry_endpoint_domain)"
hosts_file="${HOSTS_FILE:-/etc/hosts}"

if [ -z "${domain}" ]; then
  echo "Could not determine a host from AZURE_AI_PROJECT_ENDPOINT." >&2
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
' "${hosts_file}" > "${hosts_tmp}"

echo "${ip} ${domain}" >> "${hosts_tmp}"
if [ -w "${hosts_file}" ]; then
  cp "${hosts_tmp}" "${hosts_file}"
else
  sudo cp "${hosts_tmp}" "${hosts_file}"
fi
rm -f "${hosts_tmp}"

echo "Updated ${hosts_file} with ${ip} ${domain}"
