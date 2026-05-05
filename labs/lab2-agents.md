# Lab 2: Guiding Codex with AGENTS.md

<p align="center">
  <strong>👤 User:</strong> <em>"Create some code for me but follow these instructions"</em> + 📄 <strong>AGENTS.md</strong> → <img src="../uni-dev.png" width="50" alt="Codex CLI" style="vertical-align: middle;" />
</p>

Teach Codex how you want code to look by adding an `AGENTS.md` file that sets conventions for a folder before asking it to generate new code.

## Architecture & Workflow

```mermaid
graph TB
    User["👤 User"]
    
    subgraph Host["Host Environment"]
        HostFS["Host Filesystem<br/>./src/code/lab2_agents/"]
        AgentsFile["AGENTS.md"]
    end
    
    subgraph Docker["Docker Secured Container"]
        subgraph ContainerOS["Container OS"]
            Codex["<img src='../uni-dev.png' width='30' /><br/>Codex CLI"]
            ContainerFS["Container Filesystem<br/>/usr/src/app/code/lab2_agents/"]
            AgentsFS["AGENTS.md"]
        end
    end
    
    subgraph Cloud["Azure Cloud"]
        OpenAI["Codex Model<br/> (Azure Foundry)"]
    end
    
    User -.->|"① Create lab2_agents folder"| HostFS
    User -.->|"② Write AGENTS.md with style rules"| AgentsFile
    AgentsFile -.->|"③ Volume Mount (sync)"| AgentsFS
    User -.->|"④ codex 'Read AGENTS.md, Create greeter.py...'"| Codex
    Codex -->|"⑤ Read AGENTS.md context"| AgentsFS
    Codex -->|"⑥ Send prompt + AGENTS.md rules"| OpenAI
    OpenAI -->|"⑦ Return code following rules"| Codex
    Codex -->|"⑧ Write greeter.py"| ContainerFS
    ContainerFS -.->|"⑨ Volume Mount (sync)"| HostFS
    User -.->|"⑩ python greeter.py --name Ada"| Codex
    
    style Docker fill:#e1f5ff,stroke:#0078d4,stroke-width:3px,color:#000
    style Host fill:#f0f0f0,stroke:#666,stroke-width:2px,color:#000
    style Cloud fill:#fff4e1,stroke:#ff9800,stroke-width:2px,color:#000
    style ContainerOS fill:#cceeff,stroke:#0078d4,stroke-width:2px,color:#000
    style User fill:#d4edda,stroke:#28a745,stroke-width:2px,color:#000
    style AgentsFile fill:#fff9c4,stroke:#f57f17,stroke-width:2px,color:#000
    style AgentsFS fill:#fff9c4,stroke:#f57f17,stroke-width:2px,color:#000
```

**Workflow Steps:**
1. User creates lab2_agents folder on host
2. User writes AGENTS.md with coding style preferences and rules
3. AGENTS.md syncs to container via volume mount
4. User issues Codex command with explicit instruction to read AGENTS.md
5. Codex reads AGENTS.md to understand coding conventions
6. Codex sends prompt to Azure OpenAI including AGENTS.md rules as context
7. Azure OpenAI returns generated code that follows the specified rules
8. Codex writes `greeter.py` to container filesystem
9. Generated file syncs to host via volume mount
10. User executes the script to verify it follows AGENTS.md conventions

## Goal
- Capture coding preferences in `AGENTS.md` and see Codex follow them.

## Prerequisites
- Lab 1 completed and container shell open at `/usr/src/app` via `docker compose run codex /bin/bash`.
- Local `./src` folder is mounted to `/usr/src/app` inside the container.

## Steps
1. Create a dedicated workspace for this lab (inside container: `code/lab2_agents`; on host: `./src/code/lab2_agents`):
   ```bash
   mkdir -p code/lab2_agents
   ```
2. Add an `AGENTS.md` file that describes the style you want Codex to follow:
   ```bash
   cat <<'EOF' > code/lab2_agents/AGENTS.md
   # Lab 2 Agent Instructions
   - Prefer Python 3.11 scripts placed in this folder.
   - Include a short module docstring and a `main()` guarded by `if __name__ == "__main__"`.
   - Use `argparse` for command-line parsing when arguments are needed.
   - Avoid inline comments; keep the code self-explanatory.
   EOF
   ```
3. Ask Codex to generate a program that honors those instructions:
   ```bash
   codex "Read code/lab2_agents/AGENTS.md. Create code/lab2_agents/greeter.py that exposes greet(name: str) -> str and a CLI flag --name (default 'Codex') to print the greeting."
   ```
4. Inspect and run the result to confirm the agent guidance took effect:
   ```bash
   sed -n '1,160p' code/lab2_agents/greeter.py
   python code/lab2_agents/greeter.py --name Ada
   ```
5. Experiment: change the `AGENTS.md` rules (for example, ask for type hints everywhere or a different language) and regenerate to see how the output shifts.

## What to Observe
- Agent rules apply to the directory tree containing the `AGENTS.md` file.
- Persistent preferences reduce how much you must repeat in each prompt.
- Files appear in both the container path (`/usr/src/app/code/lab2_agents`) and the host path (`./src/code/lab2_agents`), confirming the mount.
