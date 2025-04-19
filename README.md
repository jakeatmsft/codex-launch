# OpenAI Codex CLI Docker Setup

This repository demonstrates how to run the OpenAI Codex CLI inside a Docker container with your local Windows folder mounted for development. It uses an `.env` file to securely provide your API key and includes `.gitignore` and `.dockerignore` to keep secrets and unnecessary files out of version control.

## Project Structure

```
C:\Working
├── Dockerfile
├── docker-compose.yml
├── .env
├── .gitignore
└── .dockerignore
```

## 1. Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop) installed and running on Windows
- A valid OpenAI API key

## 2. Create the `.env` file

In `C:\Working\.env`, add:

```env
OPENAI_API_KEY=sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

> **Note:**
>
> - Never commit the `.env` file to Git.
> - Rotate or revoke your key by updating this file.

## 3. Add Git and Docker ignores

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

## 4. Write the `Dockerfile`

Create `C:\Working\Dockerfile` with:

```dockerfile
FROM node:22-slim

# Set working directory inside container
WORKDIR /usr/src/app

# Install the Codex CLI globally
RUN npm install -g @openai/codex

# Default to bash for interactive use
CMD ["bash"]
```

## 5. Write the `docker-compose.yml`

Create `C:\Working\docker-compose.yml`:

```yaml
version: "3.9"

services:
  codex:
    build: .
    volumes:
      - C:\\Working:/usr/src/app    # Mount local Windows folder
    working_dir: /usr/src/app
    env_file:
      - .env                       # Load OPENAI_API_KEY from .env
    tty: true                      # Keep the shell open for interaction
```

## 6. Build and Run

1. Open PowerShell and navigate to your project folder:
   ```powershell
   cd C:\Working
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
     echo $OPENAI_API_KEY
     ```
   - Run Codex commands:
     ```bash
     codex "Explain what this script does"
     ```
4. Run one-off Codex commands without entering the shell:
   ```powershell
   docker-compose run codex codex "Generate a Node.js HTTP server"
   ```

## 7. Tips and Notes

- **Editing Locally:** Any edits you make in `C:\Working` are immediately available inside the container.
- **Safety:** Secrets never get baked into the image or committed to Git.
- **Extensibility:** You can add other services (databases, caches) to the `docker-compose.yml` later.

---

Happy coding with OpenAI Codex in Docker!

