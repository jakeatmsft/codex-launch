# C:\CodexApp\Dockerfile
FROM node:22-slim

# Set working dir inside container
WORKDIR /usr/src/app

# Install the Codex CLI globally
RUN npm install -g @openai/codex

# Default to bash for interactive use
CMD ["bash"]
