# OpenAI Codex CLI for Microsoft Foundry

Demo video: https://www.youtube.com/watch?v=oAc-ihUNXRE

<img src="uni-dev.png" width="120" alt="Codex CLI" align="right" />

Run the OpenAI Codex CLI against a Microsoft Foundry instant-access model with Microsoft Entra authentication, either directly on your machine or in Docker.

## Choose a workflow

1. **Local (recommended):** install and configure Codex on the host with one setup command.
2. **Docker:** keep Codex isolated and mount `./src` as its workspace.

> **Microsoft Entra-managed machines:** Use the local workflow. Device authentication policies may prevent Azure CLI authentication from working correctly inside Docker.

> **Instant access:** Create the Foundry resource and project in **West US 3** for this setup. Codex uses `gpt-5.6-sol` by model name, so no separate model deployment is required.

Both workflows now use Codex's command-backed provider authentication. Codex calls Azure CLI for a bearer token, refreshes it every five minutes, and never stores the token in this repository.

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed on the host.
- A Microsoft Foundry project in **West US 3**, the supported region for instant access during preview.
- The **Foundry User** role on the project or account.
- WSL is recommended on Windows for path and shell compatibility.
- Local workflow: Node.js, npm, and `sudo` access.
- Docker workflow: Docker Desktop with Compose.

Create or open a project in the new [Microsoft Foundry](https://ai.azure.com) experience and copy its project endpoint. It has this format:

```text
https://RESOURCE-NAME.services.ai.azure.com/api/projects/PROJECT-NAME
```

This setup uses the instant-access model `gpt-5.6-sol`, so you do not need to create a model deployment. See [Instant access to models in Microsoft Foundry](https://learn.microsoft.com/azure/foundry/concepts/instant-models#supported-models) for current availability and limitations.

## Local setup — one step

From the repository root, replace the project endpoint and run this single command:

```bash
AZURE_AI_PROJECT_ENDPOINT=https://RESOURCE-NAME.services.ai.azure.com/api/projects/PROJECT-NAME \
./local/scripts/setup-local-codex.sh
```

The setup command:

- installs `@openai/codex` when it is not already available;
- reuses `~/.azure` or starts `az login` for `~/.azure-for-codex`;
- installs the Azure token helper under `~/.codex/bin`;
- writes the Foundry provider and automatic token-refresh settings to `~/.codex/config.toml`;
- updates the managed shell block and the Foundry endpoint entry in `/etc/hosts`.

Then start Codex:

```bash
codex
```

For repeatable setup, copy [`local/.env.example`](local/.env.example) to `local/.env`, fill in the values, and rerun `./local/scripts/setup-local-codex.sh` without inline variables. See the [local setup guide](local/README.md) for overrides and troubleshooting.

## Automatic token refresh

The generated provider config uses the Foundry project endpoint and instant-access model name directly:

```toml
model = "gpt-5.6-sol"

[model_providers.azure]
name = "Microsoft Foundry"
base_url = "https://RESOURCE-NAME.services.ai.azure.com/api/projects/PROJECT-NAME/openai/v1"
wire_api = "responses"

[model_providers.azure.auth]
command = "/home/you/.codex/bin/fetch-azure-openai-token.sh"
refresh_interval_ms = 300000
timeout_ms = 5000
```

The helper requests the `https://ai.azure.com/.default` scope with `az account get-access-token` and prints only the access token to Codex. Per the [official Codex custom-provider documentation](https://learn.chatgpt.com/docs/config-file/config-advanced#custom-model-providers), Codex proactively reruns the command at `refresh_interval_ms`; a `401 Unauthorized` normally means the underlying Azure CLI session needs `az login` again.

You can override the defaults with:

```env
AZURE_OPENAI_MODEL=gpt-5.6-sol
AZURE_AI_TOKEN_SCOPE=https://ai.azure.com/.default
CODEX_AZURE_AUTH_REFRESH_INTERVAL_MS=300000
CODEX_AZURE_AUTH_TIMEOUT_MS=5000
```

## Docker setup — one step

From the repository root, replace the project endpoint and run:

```bash
AZURE_AI_PROJECT_ENDPOINT=https://RESOURCE-NAME.services.ai.azure.com/api/projects/PROJECT-NAME \
./scripts/run-codex-container.sh
```

The launcher signs in to the host profile at `~/.azure-for-docker` when needed, builds the image, and starts the container. Inside the container, Codex uses the same command-backed five-minute token refresh; no host token file or manual refresh step is required.

Run a one-off command:

```bash
AZURE_AI_PROJECT_ENDPOINT=https://RESOURCE-NAME.services.ai.azure.com/api/projects/PROJECT-NAME \
./scripts/run-codex-container.sh -- codex "Explain this repository"
```

Skip an image rebuild with `--no-build`. To keep settings in a file, copy [`.env.example`](.env.example) to `.env`, update it, and run `./scripts/run-codex-container.sh`.

## What this repo includes

- A local installer for Codex, Foundry instant-access configuration, shell setup, and host-name synchronization.
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
