# OpenAI Codex CLI Docker Setup (Azure OpenAI)

Demo video: https://www.youtube.com/watch?v=oAc-ihUNXRE

<img src="uni-dev.png" width="120" alt="Codex CLI" align="right" />

Run the OpenAI Codex CLI in Docker with Azure OpenAI authentication backed by a host-managed Entra access token.

## What this repo does

- Builds a Docker image with `@openai/codex`, Azure CLI, and helper shell setup.
- Mounts your host `./src` folder into the container at `/usr/src/app`.
- Mounts a host Azure CLI profile (`~/.azure-for-docker`) into the container at `/root/.azure`.
- Reads the token file at `/root/.azure/aoai-access-token` and exports it as `AZURE_OPENAI_API_KEY`.
- Includes a host-local setup workflow in `local/` that mirrors the same Codex auth/config behavior without Docker.

## Project structure

```text
.
├── Dockerfile
├── docker-compose.yaml
├── local/
│   ├── README.md
│   ├── .env.example
│   ├── docker/
│   └── scripts/
├── scripts/
│   ├── refresh-azure-openai-token.sh
│   └── run-codex-container.sh
├── labs/
└── src/
    ├── code/
    └── references/
```

## Prerequisites

- Docker Desktop with Compose (`docker compose`) available.
- Azure CLI installed on the host.
- WSL is recommended for Windows path compatibility.

Host-local instructions (without Docker): see `local/README.md`.

## 1. Deploy a model in Azure AI Foundry

1. Create or open a project in [Azure AI Foundry](https://ai.azure.com).
2. Deploy a coding-capable model (for example `gpt-5-codex`, `gpt-5.3-codex`, `gpt-5.4`).
3. Copy the endpoint and deployment name.

## 2. Create and sign in to a host Azure profile

Use a dedicated profile folder that Docker will mount into the container:

```bash
mkdir -p "$HOME/.azure-for-docker"
AZURE_CONFIG_DIR="$HOME/.azure-for-docker" az login
```

## 3. Create `.env`

Start from the example and update the Azure values:

```bash
cp .env.example .env
```

Required values:

```env
AZURE_OPENAI_DOMAIN=RESOURCE-NAME.openai.azure.com
AZURE_OPENAI_ENDPOINT=https://RESOURCE-NAME.openai.azure.com
AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name_here
AZURE_OPENAI_API_KEY_FILE=/root/.azure/aoai-access-token
```

## 4. Refresh the access token on the host

```bash
AZURE_CONFIG_DIR="$HOME/.azure-for-docker" \
  ./scripts/refresh-azure-openai-token.sh
```

This writes the token to:

```text
$HOME/.azure-for-docker/aoai-access-token
```

## 5. Start Codex in Docker

Recommended (auto-refresh token, optional build skip):

```bash
AZURE_CONFIG_DIR="$HOME/.azure-for-docker" \
  ./scripts/run-codex-container.sh
```

Run a one-off command:

```bash
AZURE_CONFIG_DIR="$HOME/.azure-for-docker" \
  ./scripts/run-codex-container.sh -- codex "Explain this repository"
```

Manual equivalent:

```bash
docker compose build
docker compose run --rm codex
```

Inside the container:

```bash
pwd                          # /usr/src/app (mapped from host ./src)
echo ${#AZURE_OPENAI_API_KEY}  # should be > 0
codex "Explain what is in my current environment"
```

## 6. Refresh token while container is running

1. Refresh on the host:
   ```bash
   AZURE_CONFIG_DIR="$HOME/.azure-for-docker" \
     ./scripts/refresh-azure-openai-token.sh
   ```
2. In the container shell, press Enter once so the prompt hook reloads the token file.
3. Re-check:
   ```bash
   echo ${#AZURE_OPENAI_API_KEY}
   ```

## Optional: use tmux for multiple Codex sessions

`tmux` is not installed by default in this image. Install it once inside the container if needed:

```bash
apt-get update && apt-get install -y tmux
```

Then:

```bash
tmux new -s codex
# Ctrl+b c      -> new window
# Ctrl+b % or " -> split panes
# Ctrl+b d      -> detach
tmux attach -t codex
```

## Notes

- Only `./src` is bind-mounted into the container at `/usr/src/app`.
- Keep runnable code in `src/code` and supporting docs/data in `src/references`.
- Do not commit `.env` or token files.
- Labs are under `labs/` if you want guided practice scenarios.
- If you use a different Azure profile path, update the `volumes` mount in `docker-compose.yaml` to match it.
