# AI-Aider

Dockerized [Aider](https://aider.chat) setup by [Startr.Cloud](https://startr.cloud) — optimized for **local-first and cost-effective AI coding** with Ollama, Groq, and OpenRouter.

**AI-Aider is a tool you point at projects, not a project you code inside.** Clone it once alongside your repos and use it to bring Aider into any codebase without installing Python, pip, or Aider locally.

## Why These Providers?

Aider supports dozens of LLM backends. This project defaults to three that balance cost, speed, and privacy:

| Provider | Why | Best For |
|----------|-----|----------|
| **[Ollama](https://ollama.com)** | Runs models locally — zero cost, full privacy. No API key needed. | Private repos, offline work, experimentation |
| **[Groq](https://groq.com)** | Ultra-fast inference on open models (Llama, Mixtral). Free tier available. | Speed-sensitive tasks, rapid iteration |
| **[OpenRouter](https://openrouter.ai)** | Single API key routes to 100+ models (Claude, GPT-4, Gemini, open-source). Pay-per-token. | Flexibility, model comparison, access to frontier models |

You can also use OpenAI or Anthropic keys directly — the setup supports any provider Aider does.

## Quick Start

```bash
# 1. Clone into your projects directory (alongside your other repos)
cd ~/Projects
git clone https://github.com/Startr/AI-Aider.git
cd AI-Aider
cp .env.example .env
# Edit .env with your API keys

# 2. Run Aider on THIS directory (core — lightweight)
make aider

# 3. Or point it at a sibling project
make aider WORK_DIR=~/Projects/my-web-app

# 4. Or call it from inside another project
cd ~/Projects/my-web-app
make -C ../AI-Aider aider
```

## How It Works

AI-Aider is a **harness** — a thin wrapper that runs Aider in Docker and mounts your code into the container. Your project directory structure should look like this:

```
~/Projects/
  AI-Aider/          <-- this repo (the harness)
  my-web-app/        <-- your project
  another-project/   <-- another project
  AI-OpenHands/      <-- another AI harness (see ecosystem below)
```

### Three Ways to Use It

**1. From inside AI-Aider, targeting another project:**
```bash
cd ~/Projects/AI-Aider
make aider WORK_DIR=../my-web-app
```

**2. From inside your project, calling AI-Aider's Makefile:**
```bash
cd ~/Projects/my-web-app
make -C ../AI-Aider aider WORK_DIR=$(pwd)
```
> **Note:** `make -C` changes to the Makefile's directory before running, so you must pass `WORK_DIR=$(pwd)` explicitly to mount the caller's directory.

**3. Provider shortcuts — zero config beyond the API key:**
```bash
# Local Ollama (free, private)
make aider_ollama WORK_DIR=../my-web-app

# Groq (fast, free tier)
make aider_groq WORK_DIR=../my-web-app

# OpenRouter (any model)
make aider_openrouter WORK_DIR=../my-web-app
```

## Images

| Image | Size | Includes |
|-------|------|----------|
| `paulgauthier/aider` | ~250 MB | Core Aider CLI |
| `paulgauthier/aider-full` | ~1.5 GB | + browser GUI, Playwright, interactive help |

Use **core** (`make aider`) for everyday coding. Use **full** (`make aider_full`) when you need the browser interface or web scraping.

## Configuration

Copy `.env.example` to `.env` and uncomment the providers you want:

```bash
cp .env.example .env
```

See `.env.example` for all available options. Key variables:

| Variable | Source | Notes |
|----------|--------|-------|
| `OLLAMA_API_BASE` | Local | Default: `http://host.docker.internal:11434` |
| `GROQ_API_KEY` | [console.groq.com](https://console.groq.com) | Free tier available |
| `OPENROUTER_API_KEY` | [openrouter.ai/keys](https://openrouter.ai/keys) | Pay-per-token, 100+ models |
| `OPENAI_API_KEY` | [platform.openai.com](https://platform.openai.com) | Direct OpenAI access |
| `ANTHROPIC_API_KEY` | [console.anthropic.com](https://console.anthropic.com) | Direct Claude access |
| `AIDER_MODEL` | — | Override model for any provider |
| `AIDER_FLAGS` | — | Extra CLI flags (e.g. `--dark-mode --no-auto-commits`) |
| `AIDER_TAG` | — | Docker image tag (default: `latest`) |
| `WORK_DIR` | — | Project directory to mount (default: current dir) |

Everything is also overridable on the command line:
```bash
make aider AIDER_MODEL=gpt-4o AIDER_FLAGS="--dark-mode" WORK_DIR=../my-app
```

## Make Targets

| Target | What it does |
|--------|-------------|
| `make aider` | Run Aider core image on `WORK_DIR` |
| `make aider_full` | Run Aider full image (browser GUI, Playwright) |
| `make aider_ollama` | Aider + Ollama with sensible defaults |
| `make aider_groq` | Aider + Groq (validates key) |
| `make aider_openrouter` | Aider + OpenRouter (validates key) |
| `make aider_pull` | Pull latest core + full images |
| `make aider_build` | Build custom image from local `Dockerfile` |
| `make aider_run_custom` | Run the custom-built image |
| `make show_vars` | Debug — show all resolved variables |
| `make things_clean` | Clean gitignored files (preserves `.env*`) |
| `make help` | List all available targets |

## Extending the Images

To add custom dependencies, create a `Dockerfile` in this repo:

```dockerfile
FROM paulgauthier/aider-full
RUN pip install some-extra-package
```

Then:
```bash
make aider_build        # builds the custom image
make aider_run_custom   # runs it with all the same WORK_DIR / env plumbing
```

## The AI-* Ecosystem

AI-Aider is part of a family of **agentic harness** repos following the Startr.Cloud convention. Each `AI-*` project wraps a different AI coding tool with the same pattern:

- Dockerized runtime (no local install pollution)
- Standardized Makefile with `WORK_DIR` support
- Shared `.env` convention for API keys
- Point any harness at any project

### Current and Planned Harnesses

| Repo | Tool | Status |
|------|------|--------|
| **AI-Aider** | [Aider](https://aider.chat) — terminal-based AI pair programmer | This repo |
| **AI-OpenHands** | [OpenHands](https://github.com/All-Hands-AI/OpenHands) — autonomous software agent | Planned |
| **AI-SWE-Agent** | [SWE-agent](https://github.com/princeton-nlp/SWE-agent) — Princeton's research agent | Planned |
| **AI-Goose** | [Goose](https://github.com/block/goose) — Block's autonomous dev agent | Planned |
| **AI-Continue** | [Continue](https://continue.dev) — open-source copilot for VS Code/JetBrains | Planned |
| **AI-Cline** | [Cline](https://github.com/cline/cline) — autonomous coding agent in VS Code | Planned |

### Using Multiple Harnesses on the Same Project

```bash
cd ~/Projects

# Use Aider for quick edits
make -C AI-Aider aider WORK_DIR=$(pwd)/my-web-app

# Use OpenHands for complex multi-file refactors
make -C AI-OpenHands run WORK_DIR=$(pwd)/my-web-app

# Use SWE-Agent to tackle a GitHub issue
make -C AI-SWE-Agent solve WORK_DIR=$(pwd)/my-web-app ISSUE=42

# Or from inside the project itself
cd my-web-app
make -C ../AI-Aider aider WORK_DIR=$(pwd)
```

The harnesses share the same `.env` key names where possible, so a single `.env` workflow covers all of them.

### Creating a New Harness

To scaffold a new `AI-*` harness, follow the same structure:

1. Create `AI-ToolName/` with the standard Startr Makefile
2. Add Docker targets that accept `WORK_DIR` for the project mount
3. Use `.env.example` with the common key names
4. Document the tool-specific targets in the README

## License

[GNU Affero General Public License v3.0](LICENSE)

---

Built with care by [Startr.Cloud](https://startr.cloud)
