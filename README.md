# OpenAI Codex CLI for Azure OpenAI / Azure AI Foundry

Demo video: https://www.youtube.com/watch?v=oAc-ihUNXRE

<img src="uni-dev.png" width="120" alt="Codex CLI" align="right" />

Run the OpenAI Codex CLI against Azure OpenAI with Microsoft Entra authentication, either directly on your machine or in Docker.

## Choose a workflow

1. **Local (recommended):** install and configure Codex on the host with one setup command.
2. **Docker:** keep Codex isolated and mount `./src` as its workspace.

> **Microsoft Entra-managed machines:** Use the local workflow. Device authentication policies may prevent Azure CLI authentication from working correctly inside Docker.

Both workflows now use Codex's command-backed provider authentication. Codex calls Azure CLI for a bearer token, refreshes it every five minutes, and never stores the token in this repository.

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed on the host.
- An Azure AI Foundry project with a deployed model.
- WSL is recommended on Windows for path and shell compatibility.
- Local workflow: Node.js, npm, and `sudo` access.
- Docker workflow: Docker Desktop with Compose.

Deploy a coding-capable model in [Azure AI Foundry](https://ai.azure.com), then copy its endpoint host and deployment name.

## Local setup — one step

From the repository root, replace the two placeholders and run this single command:

```bash
AZURE_OPENAI_DOMAIN=RESOURCE-NAME.openai.azure.com \
AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name_here \
./local/scripts/setup-local-codex.sh
```

The setup command:

- installs `@openai/codex` when it is not already available;
- reuses `~/.azure` or starts `az login` for `~/.azure-for-codex`;
- installs the Azure token helper under `~/.codex/bin`;
- writes the Azure provider and automatic token-refresh settings to `~/.codex/config.toml`;
- updates the managed shell block and the Azure endpoint entry in `/etc/hosts`.

Then start Codex:

```bash
codex
```

For repeatable setup, copy [`local/.env.example`](local/.env.example) to `local/.env`, fill in the values, and rerun `./local/scripts/setup-local-codex.sh` without inline variables. See the [local setup guide](local/README.md) for overrides and troubleshooting.

## Automatic token refresh

The generated provider config matches the active local configuration:

```toml
[model_providers.azure.auth]
command = "/home/you/.codex/bin/fetch-azure-openai-token.sh"
refresh_interval_ms = 300000
timeout_ms = 5000
```

The helper runs `az account get-access-token` and prints only the access token to Codex. Per the [official Codex custom-provider documentation](https://learn.chatgpt.com/docs/config-file/config-advanced#custom-model-providers), Codex proactively reruns the command at `refresh_interval_ms`; a `401 Unauthorized` normally means the underlying Azure CLI session needs `az login` again.

You can override the defaults with:

```env
AZURE_OPENAI_TOKEN_RESOURCE=https://cognitiveservices.azure.com/
CODEX_AZURE_AUTH_REFRESH_INTERVAL_MS=300000
CODEX_AZURE_AUTH_TIMEOUT_MS=5000
```

## Docker setup — one step

From the repository root, replace the placeholders and run:

```bash
AZURE_OPENAI_DOMAIN=RESOURCE-NAME.openai.azure.com \
AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name_here \
./scripts/run-codex-container.sh
```

The launcher signs in to the host profile at `~/.azure-for-docker` when needed, builds the image, and starts the container. Inside the container, Codex uses the same command-backed five-minute token refresh; no host token file or manual refresh step is required.

Run a one-off command:

```bash
AZURE_OPENAI_DOMAIN=RESOURCE-NAME.openai.azure.com \
AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name_here \
./scripts/run-codex-container.sh -- codex "Explain this repository"
```

Skip an image rebuild with `--no-build`. To keep settings in a file, copy [`.env.example`](.env.example) to `.env`, update it, and run `./scripts/run-codex-container.sh`.

## What this repo includes

- A local installer for Codex, Azure provider configuration, shell setup, and host-name synchronization.
- A Docker image with `@openai/codex`, Azure CLI, Python, and .NET 8.
- The same Azure CLI-backed token helper and refresh interval in both workflows.
- Guided exercises under [`labs/`](labs/README.md).

## Project structure

```text
.
├── Dockerfile
├── docker-compose.yaml
├── README.md
├── local/
│   ├── .env.example
│   ├── README.md
│   └── scripts/
├── scripts/
│   ├── docker-entrypoint.sh
│   ├── refresh-azure-openai-token.sh
│   └── run-codex-container.sh
├── labs/
└── src/
    ├── code/
    └── references/
```

Only `./src` is mounted into the Docker container at `/usr/src/app`. Keep runnable code in `src/code`, supporting material in `src/references`, and never commit `.env`, token files, or Azure CLI profile directories.
