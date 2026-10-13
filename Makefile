# Everyday commands. Everything runs inside the containers defined in
# compose.yaml; only Docker needs to be installed on the host.

SHELL := /bin/bash
.DEFAULT_GOAL := help

COMPOSE := docker compose
RUN := $(COMPOSE) run --rm --build app

.PHONY: help serve test lint db wasm wasm-serve wasm-verify shell bundle-update

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-14s %s\n", $$1, $$2}'

serve: ## Serve http://localhost:3000/ (db:prepare runs first and seeds a newly created database)
	$(COMPOSE) up --build app

test: ## Run the Rails test suite
	$(RUN) bin/rails test

lint: ## RuboCop and actionlint
	$(RUN) bin/rubocop
	$(COMPOSE) run --rm actionlint -color

db: ## Create or migrate the database and load the corpus (db:prepare db:seed)
	$(RUN) bin/rails db:prepare db:seed

wasm: ## Compile the app to pwa/public/app.wasm (the first run compiles CRuby, 15+ minutes), build the demo database and the site into pwa/dist
	$(RUN) bin/rails wasmify:pack demo:database
	$(RUN) bash -c "cd pwa && npm ci && npm run build"

wasm-serve: ## Serve the site built by `make wasm` at http://localhost:3000/
	$(COMPOSE) run --rm --build --service-ports app bash -c "cd pwa && npx vite preview --host 0.0.0.0 --port 3000"

wasm-verify: ## Pack the core module (no JS shim) and boot it under wasmtime
	$(RUN) bin/rails wasmify:pack:core wasmify:pack:core:verify

shell: ## A shell inside the app container
	$(RUN) bash

bundle-update: ## Re-resolve Gemfile.lock after editing the Gemfile; the image rebuilds on the next target
	$(RUN) bundle lock --update
