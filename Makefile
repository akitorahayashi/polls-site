.DEFAULT_GOAL := help

PROJECT_NAME := polls-site

# ==============================================================================
# Variables
# ==============================================================================
POSTGRES_IMAGE ?= postgres:15

# ==============================================================================
# Docker Commands
# ==============================================================================

# Define compose file combinations
DEV_COMPOSE := docker compose -f docker-compose.yml -f docker-compose.dev.override.yml --project-name $(PROJECT_NAME)-dev
PROD_COMPOSE := docker compose -f docker-compose.yml --project-name $(PROJECT_NAME)-prod
TEST_COMPOSE := docker compose -f docker-compose.yml -f docker-compose.test.override.yml --project-name $(PROJECT_NAME)-test

# ==============================================================================
# Help
# ==============================================================================

.PHONY: all
all: help ## Default target

.PHONY: help
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "; OFS=" "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ==============================================================================
# Environment Setup
# ==============================================================================

PYTHON := ./.venv/bin/python

.PHONY: setup
setup: ## Install dependencies and create .env file from .env.example
	@echo "🐍 Installing python dependencies with uv..."
	@uv sync
	@echo "📄 Creating .env file..."
	@if [ ! -f .env ] && [ -f .env.example ]; then \
		echo "Creating .env from .env.example..."; \
		cp .env.example .env; \
	fi
	@echo "✅ Setup complete. Dependencies are installed and .env file is ready."

# ==============================================================================
# Development Environment Commands
# ==============================================================================

.PHONY: up
up: ## Build images and start dev containers
	@echo "Building images and starting DEV containers..."
	@$(DEV_COMPOSE) up --build -d

.PHONY: down
down: ## Stop dev containers
	@echo "Stopping DEV containers..."
	@$(DEV_COMPOSE) down --remove-orphans

.PHONY: up-prod
up-prod: ## Build images and start prod-like containers
	@echo "Starting up PROD-like services..."
	@$(PROD_COMPOSE) up -d --build

.PHONY: down-prod
down-prod: ## Stop prod-like containers
	@echo "Shutting down PROD-like services..."
	@$(PROD_COMPOSE) down --remove-orphans

.PHONY: rebuild
rebuild: ## Rebuild services, pulling base images, without cache, and restart them
	@echo "Rebuilding all services with --no-cache and --pull..."
	@$(DEV_COMPOSE) up -d --build --no-cache --pull always --force-recreate

.PHONY: clean
clean: ## Completely remove dev containers, volumes, and orphans
	@echo "Cleaning DEV containers, volumes, and orphans..."
	@$(DEV_COMPOSE) down -v --remove-orphans

.PHONY: logs
logs: ## Show and follow dev container logs
	@echo "Showing DEV logs..."
	@$(DEV_COMPOSE) logs -f

.PHONY: shell
shell: ## Start a shell inside the dev 'web' container
	@$(DEV_COMPOSE) ps --status=running --services | grep -q '^web$$' || { echo "web container is not running. Please run 'make up' first." >&2; exit 1; }
	@$(DEV_COMPOSE) exec web /bin/sh

# ==============================================================================
# Django Management Commands
# ==============================================================================
.PHONY: makemigrations
makemigrations: ## [DEV] Create migration files
	@$(DEV_COMPOSE) exec web uv run python manage.py makemigrations

.PHONY: migrate
migrate: ## [DEV] Run database migrations
	@echo "Running DEV database migrations..."
	@$(DEV_COMPOSE) exec web uv run python manage.py migrate

.PHONY: superuser
superuser: ## [DEV] Create a Django superuser
	@echo "Creating DEV superuser..."
	@$(DEV_COMPOSE) exec web uv run python manage.py createsuperuser

.PHONY: migrate-prod
migrate-prod: ## [PROD] Run database migrations
	@echo "Running PROD-like database migrations..."
	@$(PROD_COMPOSE) exec web python manage.py migrate

.PHONY: superuser-prod
superuser-prod: ## [PROD] Create a Django superuser
	@echo "Creating PROD-like superuser..."
	@$(PROD_COMPOSE) exec web python manage.py createsuperuser

# ==============================================================================
# Testing and Code Quality
# ==============================================================================

.PHONY: format
format: ## Format code with Black and fix Ruff issues
	@echo "🎨 Formatting code with Black..."
	@$(PYTHON) -m black .
	@echo "🔧 Fixing code issues with Ruff..."
	@$(PYTHON) -m ruff check . --fix

.PHONY: lint
lint: ## Check code format and lint issues without fixing
	@echo "🔬 Checking code format with Black..."
	@$(PYTHON) -m black --check .
	@echo "🔍 Checking code issues with Ruff..."
	@$(PYTHON) -m ruff check .

.PHONY: unit-test
unit-test: ## Run the fast, database-independent unit tests locally
	@echo "🧪 Running unit tests..."
	@$(PYTHON) -m pytest tests/unit -v -s

.PHONY: db-test
db-test: ## Run the slower, database-dependent tests locally
	@echo "🗄️ Running database tests..."
	@$(PYTHON) -m pytest tests/db -v -s
	
.PHONY: e2e-test
e2e-test: ## Run end-to-end tests against a live application stack
	@echo "🔄 Running end-to-end tests..."
	@$(TEST_COMPOSE) up -d --build
	@$(PYTHON) -m pytest tests/e2e -s
	@$(TEST_COMPOSE) down

.PHONY: build-test
build-test: ## Test Docker image build without leaving artifacts
	@echo "Testing Docker image build..."
	@IMAGE_NAME="polls-site-build-test-$$(date +%s)"; \
	if docker build -t "$$IMAGE_NAME" . --target production --no-cache; then \
		echo "✅ Docker build test passed"; \
		docker rmi "$$IMAGE_NAME" >/dev/null 2>&1 || true; \
		exit 0; \
	else \
		echo "❌ Docker build test failed"; \
		docker rmi "$$IMAGE_NAME" >/dev/null 2>&1 || true; \
		exit 1; \
	fi

.PHONY: test
test: unit-test build-test db-test e2e-test ## Run the full test suite

# ==============================================================================
# Django Local Development (without Docker)
# ==============================================================================

.PHONY: run
run: ## Launch Django development server locally
	@if [ ! -f .env ]; then \
		echo "❌ Error: .env file not found. Please run 'make setup' first."; \
		exit 1; \
	fi
	@echo "🚀 Starting Django development server..."
	@export $$(cat .env | grep -v '^#' | grep -v '^$$' | xargs) && $(PYTHON) manage.py runserver

.PHONY: django-shell
django-shell: ## Start Django shell locally
	@if [ ! -f .env ]; then \
		echo "❌ Error: .env file not found. Please run 'make setup' first."; \
		exit 1; \
	fi
	@echo "🐍 Starting Django shell..."
	@export $$(cat .env | grep -v '^#' | grep -v '^$$' | xargs) && $(PYTHON) manage.py shell

.PHONY: local-migrate
local-migrate: ## Run Django migrations locally
	@if [ ! -f .env ]; then \
		echo "❌ Error: .env file not found. Please run 'make setup' first."; \
		exit 1; \
	fi
	@echo "🗄️ Running Django migrations locally..."
	@export $$(cat .env | grep -v '^#' | grep -v '^$$' | xargs) && $(PYTHON) manage.py migrate

.PHONY: local-makemigrations
local-makemigrations: ## Create Django migrations locally
	@if [ ! -f .env ]; then \
		echo "❌ Error: .env file not found. Please run 'make setup' first."; \
		exit 1; \
	fi
	@echo "📝 Creating Django migrations locally..."
	@export $$(cat .env | grep -v '^#' | grep -v '^$$' | xargs) && $(PYTHON) manage.py makemigrations

.PHONY: local-superuser
local-superuser: ## Create Django superuser locally
	@if [ ! -f .env ]; then \
		echo "❌ Error: .env file not found. Please run 'make setup' first."; \
		exit 1; \
	fi
	@echo "👤 Creating Django superuser locally..."
	@export $$(cat .env | grep -v '^#' | grep -v '^$$' | xargs) && $(PYTHON) manage.py createsuperuser

