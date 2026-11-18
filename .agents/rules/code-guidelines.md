---
trigger: always_on
---

# SAES Workspace — Multi-Repo Architecture & Development Rules

> This file is read automatically by Antigravity and AI assistants on every session from the workspace root.
> It defines the cross-repository architecture, non-negotiable development principles, and quality gates across `saes`, `saes-ai`, and `saes-ui`.

## 1. Ecosystem Overview

The SAES (Stochastic Algorithm Evaluation Suite) workspace consists of three coordinated repositories:

| Repository | Port | Role | Tech Stack |
|------------|------|------|------------|
| **`saesV2/`** | `:8060` | Core statistical Python library (`saesV2.*`) & FastAPI REST server (`saesV2.server`) | Python >= 3.11, `uv`, Pydantic V2, NumPy, SciPy, Pandas, Statsmodels, Matplotlib, Seaborn, Plotly, FastAPI |
| **`saes-ai/`** | `:8070` | Conversational statistical assistant, multi-provider LLM integrations, and MCP server (`saes_ai.*`) | Python >= 3.11, `uv`, FastAPI, MCP (`stdio` & `SSE`), Ollama, Anthropic, OpenAI, Gemini |
| **`saes-ui/`** | `:1420` | Web Single Page Application (SPA) & Tauri v2 Native Desktop Client | React 18, TypeScript 5.7 (strict), Vite 6, `pnpm`, Tauri v2 (Rust), Tailwind CSS, Radix UI, Plotly.js |

---

## 2. Non-Negotiable Architectural Rules (API-First & Thin UI)

### Rule 1: Python Programmatic API Parity
- **Every feature in the ecosystem MUST first exist as a programmatic Python API** in `saesV2` (for statistical computation, data validation, data repair/transformation, and plotting) or `saes-ai` (for AI interpretation, prompts, and agent tooling).
- Python developers using `import saesV2` or `import saes_ai` must have direct programmatic access to every capability exposed in the UI or REST endpoints.

### Rule 2: REST API Exposure
- Every feature exposed to `saes-ui` MUST have a corresponding typed FastAPI endpoint in `saesV2` (`src/saesV2/server/`) or `saes-ai` (`src/saes_ai/server/`) backed by Pydantic V2 request/response schemas.

### Rule 3: Thin Client UI — Zero Domain Computation in `saes-ui`
- **`saes-ui` MUST NOT calculate statistics, run hypothesis tests, validate domain schemas, or execute dataset repairs/transformations locally in TypeScript/JavaScript.**
- `saes-ui` is strictly a presentation, visualization, and orchestration client that consumes the `saesV2` (`:8060`) and `saes-ai` (`:8070`) REST APIs.
- All business logic, statistical decisions, assumption checks, effect sizes, data transformations, and AI interpretations must be computed by the Python backends (`saesV2` and `saes-ai`) and returned via the API.

### Rule 4: Feature Development Order
Whenever developing a new feature across the stack, follow this strict sequence:
1. **Core Python Implementation (`saesV2` / `saes-ai`)**: Implement domain models (Pydantic V2), core algorithms/functions, and public Python API exports (`saesV2/src/saesV2/api.py` or `saes-ai/src/saes_ai/`).
2. **Backend Tests**: Add unit and statistical/integration tests in `saesV2/tests/` or `saes-ai/tests/`.
3. **REST API Endpoint & MCP Tool**: Expose the Python function through FastAPI routes (`saesV2.server` / `saes_ai.server`) and, when applicable, as an MCP tool in `saes-ai`.
4. **UI Integration (`saes-ui`)**: Add typed API client bindings in `saes-ui/src/api/` and connect React components/hooks to render the backend response without duplicating computation logic.

---

## 3. Versioning, Branching & Changelog Rules

Applies identically across `saesV2/`, `saes-ai/`, and `saes-ui/`:

1. **Single Source of Truth**: `version.txt` in each repository tracks the current semver version (`X.Y.Z`, no `-SNAPSHOT` suffixes).
2. **Never Edit Versions Manually**: Never manually edit `version.txt`, `pyproject.toml`, `package.json`, or `Cargo.toml` versions. Always use `make release-stamp` (or `make release-dry-run` to preview).
3. **Changelog Maintenance**: Every feature, fix, or breaking change must be recorded under `## [Unreleased]` in the affected repository's `CHANGELOG.md` (between `## [Unreleased]` and `## [Released]` markers).
4. **Conventional Commits**: Use `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`.
5. **Branch Prefix → Version Bump**:
   - `feat/*` (default) → **Minor** (`0.2.0`)
   - `fix/*`, `patch/*`, `hotfix/*` → **Patch** (`0.1.1`)
   - `major/*` → **Major** (`1.0.0`)

---

## 4. Mandatory Quality Gate

Before finishing any task or suggesting a commit, **you MUST run `make ci`** in every modified repository (or from the workspace root):

```bash
# Run full CI across all 3 repositories from workspace root
make ci
```

What `make ci` verifies:
- **`saesV2`**: `uv run ruff check .` + `uv run mypy src` + `uv run pytest`
- **`saes-ai`**: `uv run ruff check .` + `uv run mypy src` + `uv run pytest`
- **`saes-ui`**: `pnpm lint` (ESLint 9 + Prettier) + `pnpm typecheck` (`tsc --noEmit` strict)

Never consider a task complete if `make ci` fails in any repository.

---

## 5. Workspace Root Makefile Commands

```bash
make help               # List all workspace orchestration targets
make install            # Install dependencies across saesV2, saes-ai, and saes-ui
make start              # Start all 3 services in parallel (saesV2 :8060, saes-ai :8070, saes-ui :1420)
make start-desktop      # Start saesV2 (:8060), saes-ai (:8070), and saes-ui in Tauri Desktop mode
make stop               # Stop all running services on ports 8060, 8070, and 1420
make status             # Check active status of ports 8060, 8070, and 1420
make lint               # Run linters across all 3 repos
make format             # Format code across all 3 repos
make test               # Run pytest suites in saesV2 and saes-ai
make ci                 # Run full CI validation across all 3 repos
```
