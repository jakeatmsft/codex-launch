# OpenAI Codex CLI Docker Setup

This repository demonstrates how to run the OpenAI Codex CLI inside a Docker container with your local `src` folder mounted for development. It uses an `.env` file to securely provide your API keys and includes `.gitignore` and `.dockerignore` to keep secrets and unnecessary files out of version control. The Dockerfile also writes a Codex config at `~/.codex/config.toml` that points to your Azure OpenAI endpoint.

## Project Structure

```
C:\CodexApp
├── Dockerfile
├── docker-compose.yml
├── .env
├── .gitignore
└── .dockerignore
```

## 1. Deploy a Codex model in Azure AI Foundry

1. Go to [Azure AI Foundry](https://ai.azure.com) and create a new project.
2. Select a reasoning model such as `codex-mini`, `gpt-5`, or `gpt-5-mini`.
3. Click **Deploy**, choose a name, and wait about two minutes.
4. Copy the Endpoint URL and API key.

## 2. Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop) installed and running on Windows
- A valid OpenAI API key

## 3. Create the `.env` file

In `C:\CodexApp\.env`, add the Azure settings used by the Codex config and CLI:

```env
AZURE_OPENAI_DOMAIN=RESOURCE-NAME.openai.azure.com
AZURE_OPENAI_ENDPOINT=https://RESOURCE-NAME.openai.azure.com
AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment_name_here
AZURE_OPENAI_API_KEY=your_openai_api_key_here
# Optional: keep if you also use the public OpenAI API
# OPENAI_API_KEY=sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

> **Note:**
>
> - Never commit the `.env` file to Git.
> - Rotate or revoke your keys by updating this file.
> - The container’s shell automatically loads `/usr/src/app/.env`, so your variables are available in each session.

## 4. Add Git and Docker ignores

### `.gitignore`

```gitignore
# Ignore Node modules
node_modules/

# Ignore environment files
.env

# Ignore Docker Compose overrides
docker-compose.override.yml
```

### `.dockerignore`

```dockerignore
# Exclude secrets and VCS from build context
.env
.git
node_modules
```

## 5. Write the `Dockerfile`

Create `C:\CodexApp\Dockerfile` with:

```dockerfile
FROM node:22-slim

# Set working directory inside container
WORKDIR /usr/src/app

# Install the Codex CLI globally
RUN npm install -g @openai/codex

# Default to bash for interactive use
CMD ["bash"]
```

## 6. Write the `docker-compose.yml`

Create `C:\CodexApp\docker-compose.yml`:

```yaml
version: "3.9"

services:
  codex:
    build: .
    volumes:
      - ./src:/usr/src/app/src      # Mount only the src folder
    working_dir: /usr/src/app
    env_file:
      - .env                       # Load Azure/OpenAI keys from .env
    tty: true                      # Keep the shell open for interaction
```

## 7. Build and Run

1. Open PowerShell and navigate to your project folder:
   ```powershell
   cd C:\CodexApp
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
   - Try verifying your key:
     ```bash
     echo $AZURE_OPENAI_API_KEY
     ```
   - Run Codex commands:
     ```bash
     codex "Explain what this script does"
     ```
4. Run one-off Codex commands without entering the shell:
   ```powershell
   docker-compose run codex codex "Generate a Node.js HTTP server"
   ```

## 8. Tips and Notes

- **Editing Locally:** Any edits you make under `./src` are immediately available inside `/usr/src/app/src` in the container.
- **Safety:** Secrets never get baked into the image or committed to Git.
- **Extensibility:** You can add other services (databases, caches) to the `docker-compose.yml` later.

---

Happy coding with OpenAI Codex in Docker!
