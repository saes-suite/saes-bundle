# Changelog

All notable changes to the SAES umbrella repository (desktop packaging, orchestration, and multi-platform releases) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Root `docker-compose.yml` orchestrating `saes-v2` (from PyPI `saesV2[all]`), `saes-ai`, and `saes-ui` with a shared `saes_datasets` volume (`SAES_DATASETS_DIR`) and healthchecks.
- Automatic `docker-compose.yml` tag/version synchronization in `scripts/release_stamp.js` and `.github/workflows/release-stamp.yml`.
- Docker Compose deployment instructions in `README.md`.

## [Released]

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

