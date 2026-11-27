# Changelog

All notable changes to the SAES umbrella repository (desktop packaging, orchestration, and multi-platform releases) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [Released]

## [1.1.1] — 2026-11-27 (@rorro6787)

### Changed

- Updated `saes` submodule pointer to the unified `saes-suite/saes` repository history and latest security-patched release.

### Updated Repositories
- **saes**: `2.1.1` (updated to `26cdb5a`)

## [1.1.0] — 2026-11-27 (@rorro6787)

### Added

- Bundled PEP entry-point metadata (`--copy-metadata saes`) and `saes.plugins` submodules in `packaging/build_backend.py` so frozen PyInstaller desktop sidecar builds automatically discover and mount the built-in `saes.plugins.pareto` plugin (and any installed SAES Python plugins) alongside the updated `saes`, `saes-ai`, `saes-ui`, and `saes-plugins` releases.

### Updated Repositories
- **saes**: `2.0.0` → `2.1.0`
- **saes-ai**: `0.4.1` → `0.5.0`
- **saes-ui**: `0.4.1` → `0.5.0`
- **saes-plugins**: `1.0.0` → `1.1.0`

## [1.0.1] — 2026-11-24 (@rorro6787)

### Changed

- Updated `.github/workflows/release-stamp.yml` (`commit-and-push`) to authenticate via the `saes-release-bot` GitHub App (`actions/create-github-app-token@v1`) for protected `main` rulesets, and ignored local `*.pem` / `app-id.txt` files in `.gitignore`.

### Added
- Added `make docker` target (`docker compose up -d`) to launch cached Docker images without triggering remote Git rebuilds, keeping `make docker-up` for full `--build` rebuilds.

### Fixed
- Configured `SAES_IN_DOCKER=1` and `OLLAMA_HOST=http://host.docker.internal:11434` on the `saes-ai` service in `docker-compose.yml` so containerized deployments automatically detect host Ollama models without manual URL changes in UI settings.

### Updated Repositories
- **saes-ai**: `0.4.0` → `0.4.1`

## [1.0.0] — 2026-11-24 (@rorro6787)

### Changed
- **Breaking**: Consolidated core submodule and package references from `saesV2` to canonical **`saes`** (`https://github.com/saes-suite/saes.git`, PyPI `saes[all]`, Docker service `saes`, PyInstaller sidecar, `Makefile`, `scripts/release_stamp.js`, and workspace rules).

### Added
- Root `Makefile` documentation targets (`start-docs`, `docs-serve`, `docs`, `docs-preview`) to build and preview the `saes` Material for MkDocs GitHub Pages site locally (`:8000`).
- Updated umbrella `README.md` with GitHub Pages documentation link, `saes-plugins/` architecture entry, and local documentation preview commands.

### Fixed
- Updated `packaging/build_backend.py` PyInstaller spec by removing obsolete `--collect-all tabulate` and adding explicit `statsmodels` submodules/hidden imports (`statsmodels.stats`, `statsmodels.distributions`) required by `saes` desktop sidecar builds.

### Updated Repositories
- **saes**: `2.0.0` (added)
- **saes-ai**: `0.3.2` → `0.4.0`
- **saes-ui**: `0.3.3` → `0.4.1`
- **saes-plugins**: `0.2.1` → `1.0.0`

## [0.5.0] — 2026-11-20 (@rorro6787)

### Added
- Root `docker-compose.yml` orchestrating `saes-v2` (from PyPI `saesV2[all]`), `saes-ai`, and `saes-ui` with a shared `saes_datasets` volume (`SAES_DATASETS_DIR`) and healthchecks.
- Automatic `docker-compose.yml` tag/version synchronization in `scripts/release_stamp.js` and `.github/workflows/release-stamp.yml`.
- Docker Compose deployment instructions in `README.md`.

### Updated Repositories
- **saes-ai**: `0.3.1` → `0.3.2`
- **saes-ui**: `0.3.1` → `0.3.3`
- **saes-plugins**: `0.2.0` → `0.2.1`

## [0.4.0] — 2026-11-20 (@rorro6787)

- No updates for this version

## [0.3.0] — 2026-11-19 (@rorro6787)

- No updates for this version

## [0.2.0] — 2026-11-18 (@rorro6787)

### Added
- Umbrella Tauri v2 desktop wrapper (`src-tauri/`) bundling the `saes-ui` frontend together with a unified Python backend sidecar (`saes-backend`) containing both `saesV2` (`:8060`) and `saes-ai` (`:8070`).
- PyInstaller sidecar packager (`packaging/backend_entry.py`, `packaging/build_backend.py`) for Windows, Linux, and macOS (Apple Silicon & Intel).
- Umbrella versioning (`version.txt`, `CHANGELOG.md`, `scripts/release_stamp.js`) and `Makefile` targets (`build-backend`, `build-desktop`, `release-stamp`, `release-dry-run`, `version`, `branch`).
- GitHub Actions workflows for CI (`.github/workflows/ci.yml`), automated changelog/version stamping on PR merge (`.github/workflows/release-stamp.yml`), and multi-platform desktop executable builds on every commit to `main` and `v*` tags (`.github/workflows/desktop-build.yml`).

