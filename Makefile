.PHONY: help install start start-desktop stop status start-saes start-saesV2 start-ai start-ai-debug start-ui start-ui-desktop docker-up docker-down build-backend build-desktop lint format test ci version release-dry-run release-stamp branch sync-branch

SHELL := /bin/bash
export PATH := $(HOME)/.cargo/bin:/opt/homebrew/bin:$(PATH)

BUMP   ?= minor
AUTHOR ?=
TAURI_BIN := $(CURDIR)/saes-ui/node_modules/.bin/tauri

# ── Default ──────────────────────────────────────────────────
help: ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ── Setup ────────────────────────────────────────────────────
install: ## Instala las dependencias de los 3 servicios
	@echo "📦 Instalando saesV2..."
	@$(MAKE) -C saesV2 install
	@echo "📦 Instalando saes-ai..."
	@$(MAKE) -C saes-ai install
	@echo "📦 Instalando saes-ui..."
	@$(MAKE) -C saes-ui install
	@echo "✅ Dependencias instaladas en los 3 servicios."

# ── Run (Todos los servicios) ────────────────────────────────
start: ## Levanta los 3 servicios en paralelo (saesV2 :8060, saes-ai :8070, saes-ui web :1420)
	@echo "🚀 Levantando servicios SAES..."
	@echo "   - saesV2 API:  http://localhost:8060"
	@echo "   - saes-ai API: http://localhost:8070"
	@echo "   - saes-ui Web: http://localhost:1420"
	@echo "Presiona Ctrl+C para detener todos los servicios."
	@trap 'kill 0' INT TERM EXIT; \
	$(MAKE) -C saesV2 start-api & \
	$(MAKE) -C saes-ai start-api-debug & \
	$(MAKE) -C saes-ui dev & \
	wait

start-desktop: ## Levanta los 3 servicios en paralelo con la app Desktop (Tauri) desde el umbrella
	@echo "🚀 Levantando servicios SAES (Modo Desktop)..."
	@echo "   - saesV2 API:  http://localhost:8060"
	@echo "   - saes-ai API: http://localhost:8070"
	@echo "   - SAES App:    Tauri Desktop (umbrella)"
	@echo "Presiona Ctrl+C para detener todos los servicios."
	@trap 'kill 0' INT TERM EXIT; \
	$(MAKE) -C saesV2 start-api & \
	$(MAKE) -C saes-ai start-api & \
	SAES_NO_SIDECAR=1 $(TAURI_BIN) dev & \
	wait

stop: ## Detiene los servicios que estén corriendo en los puertos 8060, 8070 y 1420
	@echo "🛑 Deteniendo servicios..."
	@-lsof -ti:8060 | xargs kill -9 2>/dev/null || true
	@-lsof -ti:8070 | xargs kill -9 2>/dev/null || true
	@-lsof -ti:1420 | xargs kill -9 2>/dev/null || true
	@echo "✅ Puertos 8060, 8070 y 1420 liberados."

status: ## Comprueba qué servicios están activos por puerto
	@echo "🔍 Estado de los servicios:"
	@lsof -Pi :8060 -sTCP:LISTEN -t >/dev/null && echo "  🟢 saesV2  (:8060) - ACTIVO" || echo "  🔴 saesV2  (:8060) - INACTIVO"
	@lsof -Pi :8070 -sTCP:LISTEN -t >/dev/null && echo "  🟢 saes-ai (:8070) - ACTIVO" || echo "  🔴 saes-ai (:8070) - INACTIVO"
	@lsof -Pi :1420 -sTCP:LISTEN -t >/dev/null && echo "  🟢 saes-ui (:1420) - ACTIVO" || echo "  🔴 saes-ui (:1420) - INACTIVO"

# ── Run (Servicios individuales) ─────────────────────────────
start-saesV2: ## Levanta únicamente el servidor API de saesV2 (:8060)
	$(MAKE) -C saesV2 start-api

start-saes: start-saesV2 ## Alias para start-saesV2

start-ai: ## Levanta únicamente el servidor API de saes-ai (:8070)
	$(MAKE) -C saes-ai start-api

start-ai-debug: ## Levanta únicamente el servidor API de saes-ai (:8070) con salida DEBUG
	$(MAKE) -C saes-ai start-api-debug

start-ui: ## Levanta únicamente el servidor web de saes-ui (:1420)
	$(MAKE) -C saes-ui dev

start-ui-desktop: ## Levanta únicamente la app desktop Tauri desde el umbrella
	$(TAURI_BIN) dev

# ── Docker (Umbrella) ────────────────────────────────────────
docker-up: ## Construye y levanta los servicios en segundo plano con Docker Compose
	docker compose up -d --build

docker-down: ## Detiene y elimina los contenedores de Docker Compose
	docker compose down

# ── Desktop Packaging (Umbrella) ─────────────────────────────
build-backend: ## Empaqueta saesV2 + saes-ai en el sidecar saes-backend con PyInstaller
	python3 packaging/build_backend.py

build-desktop: build-backend ## Genera el ejecutable/instalador desktop de SAES (UI + API + AI)
	$(TAURI_BIN) build

# ── Quality & CI ─────────────────────────────────────────────
lint: ## Ejecuta los linters en los 4 repositorios
	$(MAKE) -C saesV2 lint
	$(MAKE) -C saes-ai lint
	$(MAKE) -C saes-ui lint
	$(MAKE) -C saes-plugins lint

format: ## Formatea el código en los 3 servicios
	$(MAKE) -C saesV2 format
	$(MAKE) -C saes-ai format
	$(MAKE) -C saes-ui format

test: ## Ejecuta los tests de saesV2, saes-ai y saes-plugins
	$(MAKE) -C saesV2 test
	$(MAKE) -C saes-ai test
	$(MAKE) -C saes-plugins test

ci: ## Ejecuta las validaciones de CI en los 4 repositorios y el wrapper Tauri
	$(MAKE) -C saesV2 ci
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
version: ## Muestra la versión actual del umbrella desde version.txt
	@cat version.txt

release-dry-run: ## Previsualiza el release stamp sin modificar archivos
	@node scripts/release_stamp.js --dry-run --bump $(BUMP) $(if $(AUTHOR),--author $(AUTHOR),)

release-stamp: ## Estampa CHANGELOG.md y actualiza versión en version.txt y Tauri
	@node scripts/release_stamp.js --bump $(BUMP) $(if $(AUTHOR),--author $(AUTHOR),)

branch: ## Crea una nueva rama con el prefijo de versión correcto
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

sync-branch: ## Crea una rama en el umbrella, actualiza submódulos a main, hace commit y push
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
	echo "🌿 Creando rama '$$BRANCH' en el umbrella..."; \
	git checkout -b "$$BRANCH"; \
	echo ""; \
	for repo in saesV2 saes-ai saes-ui saes-plugins; do \
		echo "🔄 Sincronizando $$repo..."; \
		CUR_BRANCH=$$(git -C "$$repo" rev-parse --abbrev-ref HEAD); \
		if [ "$$CUR_BRANCH" != "main" ]; then \
			echo "   Cambiando de '$$CUR_BRANCH' a 'main' en $$repo..."; \
			git -C "$$repo" checkout main; \
		fi; \
		git -C "$$repo" pull; \
	done; \
	echo ""; \
	git add -A; \
	if git diff --cached --quiet; then \
		echo "ℹ️  No hay cambios para hacer commit en el umbrella."; \
	else \
		echo "📋 Cambios preparados:"; \
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
	echo "🚀 Pusheando '$$BRANCH' a origin..."; \
	git push -u origin "$$BRANCH"; \
	echo ""; \
	echo "✅ Rama '$$BRANCH' creada, submódulos sincronizados y cambios pusheados."
