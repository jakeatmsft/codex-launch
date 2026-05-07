# OpenAI Codex CLI for Azure OpenAI / Azure AI Foundry

Demo video: https://www.youtube.com/watch?v=oAc-ihUNXRE

<img src="uni-dev.png" width="120" alt="Codex CLI" align="right" />

Run the OpenAI Codex CLI against Azure OpenAI with Entra-backed auth, either in Docker or directly on your host machine.

## Choose a workflow

- Docker workflow: keep Codex isolated in a container, mount `./src` into `/usr/src/app`, and refresh a host-managed access token under `~/.azure-for-docker`.
- Local workflow: install Codex on the host and use the scripts under [`local/`](local/README.md) to write `~/.codex/config.toml`, install an Azure token helper, update `~/.bashrc`, and sync `/etc/hosts`.

## What this repo includes

- A Docker image with `@openai/codex`, Azure CLI, Python, and .NET 8.
- Host-side scripts to refresh an Azure OpenAI access token and start the Codex container.
- A host-local setup flow that configures Codex to use Azure via a command-backed auth refresh.
- Labs under [`labs/`](labs/README.md) for guided practice once Codex is running.

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
│       ├── _common.sh
│       ├── codex-local-env.sh
│       ├── fetch-azure-openai-token.sh
│       ├── setup-aoai-hosts.sh
│       ├── setup-codex-bashrc.sh
│       ├── setup-codex-config.sh
│       └── setup-local-codex.sh
├── scripts/
│   ├── refresh-azure-openai-token.sh
│   └── run-codex-container.sh
├── labs/
└── src/
    ├── code/
    └── references/
```

## Prerequisites

- Azure CLI installed on the host.
- An Azure AI Foundry project with a deployed model.
- WSL is recommended on Windows for path and shell compatibility.
- Docker Desktop with Compose if you are using the Docker workflow.
- Node.js, npm, and `sudo` access if you are using the local workflow.

## 1. Deploy a model in Azure AI Foundry

1. Create or open a project in [Azure AI Foundry](https://ai.azure.com).
2. Deploy a coding-capable model such as `gpt-5-codex`, `gpt-5.3-codex`, or `gpt-5.4`.
3. Copy the endpoint URL and deployment name.

## 2. Set your Azure OpenAI values

Both workflows need the same core Azure settings:

```env
AZURE_OPENAI_DOMAIN=RESOURCE-NAME.openai.azure.com
AZURE_OPENAI_ENDPOINT=https://RESOURCE-NAME.openai.azure.com
AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name_here
```

Optional for custom token resources:

```env
AZURE_OPENAI_TOKEN_RESOURCE=https://cognitiveservices.azure.com/
```

Use the env file that matches your workflow:

- Docker: `cp .env.example .env`
- Local: `cp local/.env.example local/.env`

The local scripts load repo-root `.env` first and then `local/.env`, so `local/.env` can override shared defaults when needed.

## Docker workflow

### 3. Create and sign in to a Docker Azure profile

Use a dedicated Azure CLI profile folder that Docker will mount into the container:

```bash
mkdir -p "$HOME/.azure-for-docker"
AZURE_CONFIG_DIR="$HOME/.azure-for-docker" az login
```

If you want Docker to mount a different host profile path, update the Azure volume in `docker-compose.yaml` to match it.

### 4. Create `.env`

Start from the example:

```bash
cp .env.example .env
```

Required Docker values:

```env
AZURE_OPENAI_DOMAIN=RESOURCE-NAME.openai.azure.com
AZURE_OPENAI_ENDPOINT=https://RESOURCE-NAME.openai.azure.com
AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name_here
AZURE_OPENAI_API_KEY_FILE=/root/.azure/aoai-access-token
```

`AZURE_OPENAI_API_KEY_FILE` is the in-container path to the token file written on the host.

### 5. Start Codex in Docker

Recommended:

```bash
AZURE_CONFIG_DIR="$HOME/.azure-for-docker" \
  ./scripts/run-codex-container.sh
```

What the launcher does:

- Verifies `az`, Docker, and Compose are available.
- Prompts for `az login` if the configured Azure profile is not signed in yet.
- Refreshes the access token into `$HOME/.azure-for-docker/aoai-access-token`.
- Builds the image unless you pass `--no-build`.

Run a one-off command:

```bash
AZURE_CONFIG_DIR="$HOME/.azure-for-docker" \
  ./scripts/run-codex-container.sh -- codex "Explain this repository"
```

Skip the build if the image is already current:

```bash
AZURE_CONFIG_DIR="$HOME/.azure-for-docker" \
  ./scripts/run-codex-container.sh --no-build
```

Manual equivalent:

```bash
AZURE_CONFIG_DIR="$HOME/.azure-for-docker" \
  ./scripts/refresh-azure-openai-token.sh
docker compose build
docker compose run --rm codex
```

Inside the container:

```bash
pwd
codex "Explain what is in my current environment"
```

### 6. Refresh the Docker token later

Refresh the host token file again at any time:

```bash
AZURE_CONFIG_DIR="$HOME/.azure-for-docker" \
  ./scripts/refresh-azure-openai-token.sh
```

New container shells will use the updated token file. Existing interactive shells should pick up the refreshed token on the next prompt or the next `codex` invocation.

## Local workflow

For the full host-local setup, see [`local/README.md`](local/README.md). The short version is:

1. Install Codex locally:
   ```bash
   npm install -g @openai/codex
   ```
2. Create local env config:
   ```bash
   cp local/.env.example local/.env
   ```
3. Sign in to Azure:
   ```bash
   mkdir -p "$HOME/.azure-for-codex"
   AZURE_CONFIG_DIR="$HOME/.azure-for-codex" az login
   ```
4. Run the setup chain:
   ```bash
   AZURE_CONFIG_DIR="$HOME/.azure-for-codex" \
     ./local/scripts/setup-local-codex.sh
   ```
5. Reload your shell and start Codex:
   ```bash
   source ~/.bashrc
   codex
   ```

The local setup scripts:

- Install `~/.codex/bin/fetch-azure-openai-token.sh`.
- Write `~/.codex/config.toml` with `model_provider = "azure"` and an auth command.
- Add a managed `codex-launch` block to `~/.bashrc`.
- Update `/etc/hosts` for `AZURE_OPENAI_DOMAIN`.

If you already use the default Azure CLI profile at `~/.azure`, the local setup can create `~/.azure-for-codex -> ~/.azure` automatically.

## Labs and notes

- Labs live under [`labs/`](labs/README.md) and assume you are working against the mounted `src/` workspace.
- Only `./src` is bind-mounted into the Docker container at `/usr/src/app`.
- Keep runnable code in `src/code` and supporting material in `src/references`.
- Do not commit `.env`, token files, or Azure CLI profile directories.
