---
trigger: always_on
---

# SAES Workspace — Multi-Repo Architecture & Development Rules

> This file is read automatically by Antigravity and AI assistants on every session from the workspace root.
> It defines the cross-repository architecture, non-negotiable development principles, and quality gates across `saes`, `saes-ai`, `saes-ui`, and `saes-plugins`.

## 1. Ecosystem Overview

The SAES (Stochastic Algorithm Evaluation Suite) workspace consists of four coordinated repositories:

| Repository | Port | Role | Tech Stack |
|------------|------|------|------------|
| **`saes/`** | `:8060` | Core statistical Python library (`saes.*`) & FastAPI REST server (`saes.server`) | Python >= 3.11, `uv`, Pydantic V2, NumPy, SciPy, Pandas, Statsmodels, Matplotlib, Seaborn, Plotly, FastAPI |
| **`saes-ai/`** | `:8070` | Conversational statistical assistant, multi-provider LLM integrations, and MCP server (`saes_ai.*`) | Python >= 3.11, `uv`, FastAPI, MCP (`stdio` & `SSE`), Ollama, Anthropic, OpenAI, Gemini |
| **`saes-ui/`** | `:1420` | Web Single Page Application (SPA) (wrapped by umbrella `src-tauri/` for Tauri v2 Desktop) | React 18, TypeScript 5.7 (strict), Vite 6, `pnpm`, Tailwind CSS, Radix UI, Plotly.js |
| **`saes-plugins/`** | `—` | Claude Code plugin marketplace & agentic development skills for `saes` | Markdown (`SKILL.md`), JSON manifests, Python/Node CI & release scripts |

---

## 2. Non-Negotiable Architectural Rules (API-First & Thin UI)

### Rule 1: Python Programmatic API Parity
- **Every feature in the ecosystem MUST first exist as a programmatic Python API** in `saes` (for statistical computation, data validation, data repair/transformation, and plotting) or `saes-ai` (for AI interpretation, prompts, and agent tooling).
- Python developers using `import saes` or `import saes_ai` must have direct programmatic access to every capability exposed in the UI or REST endpoints.

### Rule 2: REST API Exposure
- Every feature exposed to `saes-ui` MUST have a corresponding typed FastAPI endpoint in `saes` (`src/saes/server/`) or `saes-ai` (`src/saes_ai/server/`) backed by Pydantic V2 request/response schemas.

### Rule 3: Thin Client UI — Zero Domain Computation in `saes-ui`
- **`saes-ui` MUST NOT calculate statistics, run hypothesis tests, validate domain schemas, or execute dataset repairs/transformations locally in TypeScript/JavaScript.**
- `saes-ui` is strictly a presentation, visualization, and orchestration client that consumes the `saes` (`:8060`) and `saes-ai` (`:8070`) REST APIs.
- All business logic, statistical decisions, assumption checks, effect sizes, data transformations, and AI interpretations must be computed by the Python backends (`saes` and `saes-ai`) and returned via the API.

### Rule 4: Feature Development Order
Whenever developing a new feature across the stack, follow this strict sequence:
1. **Core Python Implementation (`saes` / `saes-ai`)**: Implement domain models (Pydantic V2), core algorithms/functions, and public Python API exports (`saes/src/saes/api.py` or `saes-ai/src/saes_ai/`).
2. **Backend Tests**: Add unit and statistical/integration tests in `saes/tests/` or `saes-ai/tests/`.
3. **REST API Endpoint & MCP Tool**: Expose the Python function through FastAPI routes (`saes.server` / `saes_ai.server`) and, when applicable, as an MCP tool in `saes-ai`.
4. **UI Integration (`saes-ui`)**: Add typed API client bindings in `saes-ui/src/api/` and connect React components/hooks to render the backend response without duplicating computation logic.

### Rule 5: Claude Plugin Synchronization (`saes-plugins`)
- Whenever public Python APIs in `saes` (`src/saes/__init__.py`, `src/saes/api.py`, public domain models/exceptions, CSV schema, plot types, or table export options) are added, modified, or removed, **you MUST update the corresponding `SKILL.md` files in `saes-plugins/plugins/saes/skills/`** in the same task to prevent API drift.
- Record the update under `## [Unreleased]` in `saes-plugins/CHANGELOG.md` and run `make -C saes-plugins ci`.
- **Independent Versioning**: `saes-plugins/version.txt` versions the plugin itself, not `saes`. Internal refactors or `patch` bugfixes in `saes` that do not alter the public API or methodology do not require changes in `saes-plugins`.
- **Library Target Version (`saes >= X.Y.Z`)**: Keep the minimum compatible `saes` version in `saes-plugins/plugins/saes/skills/saes-python-api/SKILL.md`. Do not bump it on every `saes` patch/minor release unless a new feature requires a higher minimum version or a `major` breaking change in `saes` requires raising the floor (accompanied by a `major` bump of `saes-plugins`).

---

## 3. Versioning, Branching & Changelog Rules

Applies identically across `saes/`, `saes-ai/`, `saes-ui/`, and `saes-plugins/`:

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
- **`saes`**: `uv run ruff check .` + `uv run mypy src` + `uv run pytest`
- **`saes-ai`**: `uv run ruff check .` + `uv run mypy src` + `uv run pytest`
- **`saes-ui`**: `pnpm lint` (ESLint 9 + Prettier) + `pnpm typecheck` (`tsc --noEmit` strict)
- **`saes-plugins`**: `python3 scripts/validate.py` (`make -C saes-plugins ci`)

Never consider a task complete if `make ci` fails in any repository.

---

## 5. Workspace Root Makefile Commands

```bash
make help               # List all workspace orchestration targets
make install            # Install dependencies across saes, saes-ai, and saes-ui
make start              # Start all 3 services in parallel (saes :8060, saes-ai :8070, saes-ui :1420)
make start-desktop      # Start saes (:8060), saes-ai (:8070), and saes-ui in Tauri Desktop mode
make stop               # Stop all running services on ports 8060, 8070, and 1420
make status             # Check active status of ports 8060, 8070, and 1420
make lint               # Run linters across all 3 repos
make format             # Format code across all 3 repos
make test               # Run pytest suites in saes and saes-ai
make ci                 # Run full CI validation across all 3 repos
```
