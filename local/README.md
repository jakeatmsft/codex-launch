# Local Codex setup (no Docker)

The local workflow installs Codex and configures Azure OpenAI with Microsoft Entra authentication in one command.

## Prerequisites

- Azure CLI
- Node.js and npm
- `sudo` access for the `/etc/hosts` update
- An Azure AI Foundry endpoint and deployment

## Run setup

From the repository root, replace the placeholders and run:

```bash
AZURE_OPENAI_DOMAIN=RESOURCE-NAME.openai.azure.com \
AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name_here \
./local/scripts/setup-local-codex.sh
```

If Azure CLI is not signed in, the command starts `az login`. If Codex is not installed, it installs `@openai/codex` with npm.

After setup completes, run:

```bash
codex
```

For repeatable setup, copy the example environment file once, fill in its values, and rerun the same setup script:

```bash
cp local/.env.example local/.env
```

The scripts load repo-root `.env` first and `local/.env` second, so local values take precedence.

## Token refresh configuration

Setup installs `~/.codex/bin/fetch-azure-openai-token.sh` and writes this provider authentication block to `~/.codex/config.toml`:

```toml
[model_providers.azure.auth]
command = "/home/you/.codex/bin/fetch-azure-openai-token.sh"
refresh_interval_ms = 300000
timeout_ms = 5000
```

Codex calls the helper without stdin. The helper runs `az account get-access-token`, writes the token to stdout, and Codex proactively requests a new token every five minutes. This follows the [official command-backed authentication configuration](https://learn.chatgpt.com/docs/config-file/config-advanced#custom-model-providers).

Optional environment overrides:

```env
AZURE_OPENAI_ENDPOINT=https://RESOURCE-NAME.openai.azure.com
AZURE_OPENAI_API_VERSION=2025-04-01-preview
AZURE_OPENAI_TOKEN_RESOURCE=https://cognitiveservices.azure.com/
CODEX_MODEL_REASONING_EFFORT=high
CODEX_AZURE_AUTH_REFRESH_INTERVAL_MS=300000
CODEX_AZURE_AUTH_TIMEOUT_MS=5000
```

## What setup changes

- `~/.codex/bin/fetch-azure-openai-token.sh`: installed credential helper.
- `~/.codex/config.toml`: Azure model provider and auth settings.
- `~/.bashrc`: managed `codex-launch` environment block.
- `/etc/hosts`: refreshed entry for `AZURE_OPENAI_DOMAIN`.
- `~/.azure-for-codex`: dedicated Azure CLI profile, or a link to an existing `~/.azure` profile.

The setup scripts are idempotent and may be rerun after changing settings.

## Troubleshooting

If Codex returns `401 Unauthorized`, renew the Azure session and retry:

```bash
AZURE_CONFIG_DIR="$HOME/.azure-for-codex" az login
codex
```

To run individual setup components:

```bash
./local/scripts/setup-codex-config.sh
./local/scripts/setup-codex-bashrc.sh
./local/scripts/setup-aoai-hosts.sh
```
