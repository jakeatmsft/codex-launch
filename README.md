# Start Vibe Coding today!
🎥 Demo video: https://www.youtube.com/watch?v=oAc-ihUNXRE

# OpenAI Codex CLI Docker Setup

<img src="uni-dev.png" width="120" alt="Codex CLI" align="right" />

> *Have you ever wished you had the skills of a unicorn developer?* 🦄

With OpenAI Codex models, you can. Codex transforms natural language into working code, enabling you to tackle any development task—from generating boilerplate and refactoring legacy systems to writing tests, debugging complex issues, and building entire features from a simple description. Whether you're a seasoned engineer or just getting started, Codex amplifies your capabilities, letting you focus on *what* you want to build while it handles the *how*.

Unlike IDE-based AI assistants that operate in a sandbox, the Codex CLI has access to your filesystem—it can read, write, move, and delete files, run shell commands, execute scripts, and interact with your entire development environment. This means Codex can scaffold projects, install dependencies, run builds, and even deploy your code. Plus, you're not locked into a single model: choose from a range of reasoning models and are not limited by the IDE rate-limiting your requests.

This repository demonstrates how to run the OpenAI Codex CLI inside a Docker container with your local project folder mounted for development. It uses an `.env` file for Azure endpoint/model settings and injects an Entra access token as `AZURE_OPENAI_API_KEY` from a host-managed token file. The Dockerfile also writes a Codex config at `~/.codex/config.toml` that points to your Azure OpenAI endpoint.

## Project Structure

```
.
├── Dockerfile
├── docker-compose.yml
├── .env
├── .gitignore
├── .dockerignore
└── src
    ├── code
    └── reference
```

Place your application code in `src/code` and any reference materials (docs, snippets, sample data) in `src/reference`. The whole project is mounted into the container at `/usr/src/app`.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop) installed and running on Windows
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed in your host environment (WSL recommended for this flow)


## 1. Deploy a Codex model in Azure AI Foundry

1. Go to [Azure AI Foundry](https://ai.azure.com) and create a new project.
2. Select a SOTA coding model such as `gpt-5-codex`, `gpt-5.1-codex-max`, or `gpt-5.2-codex` (NEW).
3. Click **Deploy**, choose a name, and wait about two minutes.
4. Copy the Endpoint URL and deployment name.

## 2. Create a host Azure CLI profile for Docker

Open WSL and create a separate Azure CLI profile that the container can mount:

```bash
cd /mnt/c/Users/<your-username>
mkdir -p .azure-for-docker
AZURE_CONFIG_DIR=./.azure-for-docker az login
```

## 3. Create the `.env` file

In the project root `.env`, add the Azure settings used by the Codex config and CLI:

```env
AZURE_OPENAI_DOMAIN=RESOURCE-NAME.openai.azure.com
AZURE_OPENAI_ENDPOINT=https://RESOURCE-NAME.openai.azure.com
AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name_here
AZURE_OPENAI_API_KEY_FILE=/root/.azure/aoai-access-token

```

> **Note:**
>
> - Never commit the `.env` file to Git.
> - `AZURE_OPENAI_API_KEY_FILE` is the token file path inside the container.
> - The container’s shell automatically loads `/usr/src/app/.env`, so your variables are available in each session.

## 4. Refresh the access token on the host

From the repository root in WSL:

```bash
AZURE_CONFIG_DIR=/mnt/c/Users/<your-username>/.azure-for-docker ./scripts/refresh-azure-openai-token.sh
```

This writes a fresh token to:

```text
/mnt/c/Users/<your-username>/.azure-for-docker/aoai-access-token
```

## 5. Build and Run

1. Open PowerShell (or your preferred shell) and navigate to your project folder:
   ```powershell
   cd /path/to/your/project
   ```
2. Build the Docker image:
   ```powershell
   docker-compose build
   ```
3. Start an interactive shell session in the container:
   ```powershell
   docker-compose run codex
   ```
   - You will be at `/usr/src/app` inside the container.
   - Verify token injection:
     ```bash
     echo ${#AZURE_OPENAI_API_KEY}
     ```
   - Run Codex commands:
     ```bash
     codex "Explain what is in my current environment"
     ```
4a. Run one-off Codex commands without entering the shell:
   ```powershell
   docker-compose run codex codex "Generate a Node.js HTTP server"
   ```

4b. Connect to the container and run command `codex` for interactive shell
   ```powershell
   docker compose run codex /bin/bash

   $:/usr/src/app# codex 
   ```

## 6. Refresh token while container is already running

1. On the host, refresh the token again:
   ```bash
   AZURE_CONFIG_DIR=/mnt/c/Users/<your-username>/.azure-for-docker ./scripts/refresh-azure-openai-token.sh
   ```
2. In the open container shell, press Enter once (the prompt hook reloads the token file).
3. Re-check:
   ```bash
   echo ${#AZURE_OPENAI_API_KEY}
   ```

## 7. Coordinate multiple Codex sessions with tmux

Use `tmux` inside the container to run and monitor multiple Codex sessions in one terminal:

1. Start a session (from inside the container):
   ```bash
   tmux new -s codex
   ```
2. Open extra views for parallel work:
   - New window: press `Ctrl+b` then `c`.
   - Split pane: press `Ctrl+b` then `%` (vertical) or `"` (horizontal).
3. Run `codex` in each pane/window; all share the same mounted `src` folder and environment.
4. Detach and reattach without losing state:
   ```bash
   Ctrl+b d        # detach
   tmux ls         # list sessions
   tmux attach -t codex
   ```

### Tips and Notes

- **Editing Locally:** Any edits you make under `./src` are immediately available inside `/usr/src/app/src` in the container.
- **Project layout:** Keep runnable or draft code in `./src/code` and store reference files or supporting material in `./src/reference`.
- **Safety:** Secrets never get baked into the image or committed to Git.
- **Extensibility:** You can add other services (databases, caches) to the `docker-compose.yml` later.

---

Happy coding with OpenAI Codex in Docker!
