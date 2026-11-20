<p align="center">
  <img src="src-tauri/app-icon.svg" alt="SAES Logo" width="128" />
</p>

<h1 align="center">SAES — Stochastic Algorithm Evaluation Suite</h1>

<p align="center">
  Automated statistical analysis, hypothesis testing, AI-assisted interpretation, and interactive visualization workbench.
</p>

---

## Architecture

| Repository | Port | Role |
|---|---|---|
| [`saesV2/`](saesV2/README.md) | `:8060` | Core statistical Python library (`saesV2`) and FastAPI REST server |
| [`saes-ai/`](saes-ai/README.md) | `:8070` | Conversational AI assistant, multi-provider LLM connectors, and MCP server |
| [`saes-ui/`](saes-ui/README.md) | `:1420` | React + TypeScript + Vite web frontend |
| `src-tauri/` + `packaging/` | — | Umbrella Tauri v2 desktop wrapper bundling `saes-ui` and the unified `saes-backend` PyInstaller sidecar |

---

## Quickstart

```bash
make install        # Install dependencies across saesV2, saes-ai, and saes-ui
make start          # Start all 3 services (saesV2 :8060, saes-ai :8070, saes-ui :1420)
make start-desktop  # Start all 3 services with Tauri Desktop in dev mode
make build-desktop  # Package saes-backend sidecar and build Tauri desktop installer
make ci             # Run lint, typecheck, tests, and cargo check across all repos
```

---

## Docker Compose Deployment

Run the full web stack (`saes-v2` from PyPI `saesV2[all]`, `saes-ai`, and `saes-ui`) using [docker-compose.yml](docker-compose.yml):

```bash
docker compose up -d --build
```

- **UI**: `http://localhost:1420`
- **saesV2 API**: `http://localhost:8060`
- **saes-ai API**: `http://localhost:8070`
- **Shared datasets**: Persisted in the `saes_datasets` Docker volume (`/data/datasets` via `SAES_DATASETS_DIR`).
- **LLM providers**: Pass `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or `GEMINI_API_KEY` in the environment (or `.env`), or connect to a host Ollama instance via `http://host.docker.internal:11434`.

---

## Desktop App Installation (macOS)

If macOS Gatekeeper blocks the downloaded `SAES.app` (e.g., *"SAES.app is damaged and can't be opened"* or *"cannot be opened because the developer cannot be verified"*), move `SAES.app` to `/Applications` and remove the quarantine attribute with:

```bash
xattr -cr /Applications/SAES.app
```
