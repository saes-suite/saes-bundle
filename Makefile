.PHONY: help install start start-desktop stop status start-saes start-ai start-ai-debug start-ui start-ui-desktop start-docs docs docs-serve docs-preview docker-up docker-down build-backend build-desktop lint format test ci version release-dry-run release-stamp branch sync-branch

SHELL := /bin/bash
export PATH := $(HOME)/.cargo/bin:/opt/homebrew/bin:$(PATH)

BUMP      ?= minor
AUTHOR    ?=
DOCS_PORT ?= 8000
TAURI_BIN := $(CURDIR)/saes-ui/node_modules/.bin/tauri

# ── Default ──────────────────────────────────────────────────
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ── Setup ────────────────────────────────────────────────────
install: ## Install dependencies across all 3 services
	@echo "📦 Installing saes..."
	@$(MAKE) -C saes install
	@echo "📦 Installing saes-ai..."
	@$(MAKE) -C saes-ai install
	@echo "📦 Installing saes-ui..."
	@$(MAKE) -C saes-ui install
	@echo "✅ Dependencies installed across all 3 services."

# ── Run (All services) ───────────────────────────────────────
start: ## Start all 3 services in parallel (saes :8060, saes-ai :8070, saes-ui web :1420)
	@echo "🚀 Starting SAES services..."
	@echo "   - saes API:  http://localhost:8060"
	@echo "   - saes-ai API: http://localhost:8070"
	@echo "   - saes-ui Web: http://localhost:1420"
	@echo "Press Ctrl+C to stop all services."
	@trap 'kill 0' INT TERM EXIT; \
	$(MAKE) -C saes start-api & \
	$(MAKE) -C saes-ai start-api-debug & \
	$(MAKE) -C saes-ui dev & \
	wait

start-desktop: ## Start all 3 services in parallel with the Tauri Desktop app from the umbrella
	@echo "🚀 Starting SAES services (Desktop Mode)..."
	@echo "   - saes API:  http://localhost:8060"
	@echo "   - saes-ai API: http://localhost:8070"
	@echo "   - SAES App:    Tauri Desktop (umbrella)"
	@echo "Press Ctrl+C to stop all services."
	@trap 'kill 0' INT TERM EXIT; \
	$(MAKE) -C saes start-api & \
	$(MAKE) -C saes-ai start-api & \
	SAES_NO_SIDECAR=1 $(TAURI_BIN) dev & \
	wait

stop: ## Stop any services running on ports 8060, 8070, and 1420
	@echo "🛑 Stopping services..."
	@-lsof -ti:8060 | xargs kill -9 2>/dev/null || true
	@-lsof -ti:8070 | xargs kill -9 2>/dev/null || true
	@-lsof -ti:1420 | xargs kill -9 2>/dev/null || true
	@echo "✅ Ports 8060, 8070, and 1420 freed."

status: ## Check which services are active by port
	@echo "🔍 Service status:"
	@lsof -Pi :8060 -sTCP:LISTEN -t >/dev/null && echo "  🟢 saes  (:8060) - ACTIVE" || echo "  🔴 saes  (:8060) - INACTIVE"
	@lsof -Pi :8070 -sTCP:LISTEN -t >/dev/null && echo "  🟢 saes-ai (:8070) - ACTIVE" || echo "  🔴 saes-ai (:8070) - INACTIVE"
	@lsof -Pi :1420 -sTCP:LISTEN -t >/dev/null && echo "  🟢 saes-ui (:1420) - ACTIVE" || echo "  🔴 saes-ui (:1420) - INACTIVE"

# ── Run (Individual services) ────────────────────────────────
start-saes: ## Start only the saes REST API server (:8060)
	$(MAKE) -C saes start-api

start-ai: ## Start only the saes-ai REST API server (:8070)
	$(MAKE) -C saes-ai start-api

start-ai-debug: ## Start only the saes-ai REST API server (:8070) with DEBUG output
	$(MAKE) -C saes-ai start-api-debug

start-ui: ## Start only the saes-ui web dev server (:1420)
	$(MAKE) -C saes-ui dev

start-ui-desktop: ## Start only the Tauri Desktop app from the umbrella
	$(TAURI_BIN) dev

# ── Documentation (GitHub Pages) ─────────────────────────────
start-docs: ## Serve the GitHub Pages documentation locally with live-reload (:8000)
	$(MAKE) -C saes docs-serve DOCS_PORT=$(DOCS_PORT)

docs-serve: start-docs ## Alias for start-docs

docs: ## Build the static GitHub Pages documentation in strict mode
	$(MAKE) -C saes docs

docs-preview: ## Build and serve the exact static GitHub Pages bundle locally (:8000)
	$(MAKE) -C saes docs-preview DOCS_PORT=$(DOCS_PORT)

# ── Docker (Umbrella) ────────────────────────────────────────
docker-up: ## Build and start services in the background with Docker Compose
	docker compose up -d --build

docker-down: ## Stop and remove Docker Compose containers
	docker compose down

# ── Desktop Packaging (Umbrella) ─────────────────────────────
build-backend: ## Package saes + saes-ai into the saes-backend PyInstaller sidecar
	python3 packaging/build_backend.py

build-desktop: build-backend ## Build the SAES desktop executable/installer (UI + API + AI)
	$(TAURI_BIN) build

# ── Quality & CI ─────────────────────────────────────────────
lint: ## Run linters across all 4 repositories
	$(MAKE) -C saes lint
	$(MAKE) -C saes-ai lint
	$(MAKE) -C saes-ui lint
	$(MAKE) -C saes-plugins lint

format: ## Format code across all 3 services
	$(MAKE) -C saes format
	$(MAKE) -C saes-ai format
	$(MAKE) -C saes-ui format

test: ## Run tests in saes, saes-ai, and saes-plugins
	$(MAKE) -C saes test
	$(MAKE) -C saes-ai test
	$(MAKE) -C saes-plugins test

ci: ## Run full CI checks across all 4 repositories and the Tauri wrapper
	$(MAKE) -C saes ci
	$(MAKE) -C saes-ai ci
	$(MAKE) -C saes-ui ci
	$(MAKE) -C saes-plugins ci
	@CREATED_PLACEHOLDER=0; \
	if [ ! -d "src-tauri/binaries/saes-backend" ]; then mkdir -p src-tauri/binaries/saes-backend && touch src-tauri/binaries/saes-backend/.gitkeep && CREATED_PLACEHOLDER=1; fi; \
	cargo check --manifest-path src-tauri/Cargo.toml; \
	STATUS=$$?; \
	if [ "$$CREATED_PLACEHOLDER" = "1" ]; then rm -rf src-tauri/binaries/saes-backend; fi; \
	exit $$STATUS

# ── Release & Versioning (Umbrella) ──────────────────────────
version: ## Print the current umbrella version from version.txt
	@cat version.txt

release-dry-run: ## Preview the release stamp without modifying files
	@node scripts/release_stamp.js --dry-run --bump $(BUMP) $(if $(AUTHOR),--author $(AUTHOR),)

release-stamp: ## Stamp CHANGELOG.md and update version in version.txt and Tauri
	@node scripts/release_stamp.js --bump $(BUMP) $(if $(AUTHOR),--author $(AUTHOR),)

branch: ## Create a new branch with the proper version bump prefix
	@echo ""; \
	echo "Select version bump type for this branch:"; \
	echo "  1) minor  (default — new feature, X.Y+1.0)"; \
	echo "  2) patch  (bugfix / hotfix, X.Y.Z+1)"; \
	echo "  3) major  (breaking change, X+1.0.0)"; \
	echo ""; \
	printf "Choice [1]: "; \
	read CHOICE; \
	case "$${CHOICE:-1}" in \
		1) PREFIX="feat" ;; \
		2) PREFIX="fix" ;; \
		3) PREFIX="major" ;; \
		*) echo "Invalid choice"; exit 1 ;; \
	esac; \
	echo ""; \
	printf "Branch name (e.g. add-feature): "; \
	read NAME; \
	if [ -z "$$NAME" ]; then \
		echo "ERROR: branch name cannot be empty"; \
		exit 1; \
	fi; \
	BRANCH="$$PREFIX/$$NAME"; \
	echo ""; \
	echo "Creating branch: $$BRANCH"; \
	git checkout -b "$$BRANCH"; \
	echo ""; \
	echo "✅ Branch '$$BRANCH' created."; \
	echo "📝 Remember to add your changes to CHANGELOG.md under ## [Unreleased]"

sync-branch: ## Create an umbrella branch, sync submodules to main, commit, and push
	@set -e; \
	echo ""; \
	echo "Select branch type:"; \
	echo "  1) feat   (minor — new feature)"; \
	echo "  2) fix    (patch — bugfix / hotfix)"; \
	echo "  3) major  (major — breaking change)"; \
	echo ""; \
	printf "Choice [1]: "; \
	read CHOICE; \
	case "$${CHOICE:-1}" in \
		1) PREFIX="feat" ;; \
		2) PREFIX="fix" ;; \
		3) PREFIX="major" ;; \
		*) echo "ERROR: invalid choice"; exit 1 ;; \
	esac; \
	echo ""; \
	printf "Branch name (e.g. sync-submodules): "; \
	read NAME; \
	if [ -z "$$NAME" ]; then \
		echo "ERROR: branch name cannot be empty"; \
		exit 1; \
	fi; \
	BRANCH="$$PREFIX/$$NAME"; \
	echo ""; \
	echo "🌿 Creating branch '$$BRANCH' in umbrella..."; \
	git checkout -b "$$BRANCH"; \
	echo ""; \
	for repo in saes saes-ai saes-ui saes-plugins; do \
		echo "🔄 Syncing $$repo..."; \
		CUR_BRANCH=$$(git -C "$$repo" rev-parse --abbrev-ref HEAD); \
		if [ "$$CUR_BRANCH" != "main" ]; then \
			echo "   Switching from '$$CUR_BRANCH' to 'main' in $$repo..."; \
			git -C "$$repo" checkout main; \
		fi; \
		git -C "$$repo" pull; \
	done; \
	echo ""; \
	git add -A; \
	if git diff --cached --quiet; then \
		echo "ℹ️  No changes to commit in umbrella."; \
	else \
		echo "📋 Staged changes:"; \
		git status -s; \
		echo ""; \
		printf "Commit message: "; \
		read COMMIT_MSG; \
		if [ -z "$$COMMIT_MSG" ]; then \
			echo "ERROR: commit message cannot be empty"; \
			exit 1; \
		fi; \
		git commit -m "$$COMMIT_MSG"; \
	fi; \
	echo ""; \
	echo "🚀 Pushing '$$BRANCH' to origin..."; \
	git push -u origin "$$BRANCH"; \
	echo ""; \
	echo "✅ Branch '$$BRANCH' created, submodules synced, and changes pushed."
