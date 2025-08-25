.DEFAULT_GOAL := help

PROJECT_NAME := $(shell basename $(CURDIR))

.PHONY: all
all: help ## Default target

# ==============================================================================
# Docker Commands
# ==============================================================================

# Docker Compose command wrappers
DEV_COMPOSE := sudo docker compose --project-name $(PROJECT_NAME)-dev
PROD_COMPOSE := sudo docker compose -f docker-compose.yml --project-name $(PROJECT_NAME)-prod

# ==============================================================================
# Environment Setup
# ==============================================================================

# [Internal] Switch .env symlink based on the environment
.PHONY: switch-env-dev
switch-env-dev:
	@[ -f .env.dev ] || { [ -f .env.example ] && cp .env.example .env.dev && echo "Created .env.dev from .env.example"; } || true
	@ln -sf .env.dev .env && echo "Switched to DEV (.env -> .env.dev)"

.PHONY: switch-env-prod
switch-env-prod:
	@[ -f .env.prod ] || { [ -f .env.example ] && cp .env.example .env.prod && echo "Created .env.prod from .env.example"; } || true
	@ln -sf .env.prod .env && echo "Switched to PROD (.env -> .env.prod)"

.PHONY: setup
setup: ## Create .env files and pull test images
	@([ -f .env.example ] && [ ! -f .env.dev ]) && cp .env.example .env.dev && echo "Created .env.dev from .env.example" || echo ".env.dev already exists or template not found. Skipping."
	@([ -f .env.example ] && [ ! -f .env.prod ]) && cp .env.example .env.prod && echo "Created .env.prod from .env.example" || echo ".env.prod already exists or template not found. Skipping."
	@echo "Pulling postgres image for tests..."
	@sudo docker pull postgres:15

# ==============================================================================
# Development Environment Commands
# ==============================================================================

.PHONY: up
up: switch-env-dev ## Build images and start dev containers
	@echo "Building images and starting DEV containers..."
	@$(DEV_COMPOSE) up --build -d

.PHONY: down
down: switch-env-dev ## Stop dev containers
	@echo "Stopping DEV containers..."
	@$(DEV_COMPOSE) down --remove-orphans

.PHONY: clean
clean: switch-env-dev ## Completely remove dev containers, volumes, and orphans
	@echo "Cleaning DEV containers, volumes, and orphans..."
	@$(DEV_COMPOSE) down -v --remove-orphans

.PHONY: logs
logs: switch-env-dev ## Show and follow dev container logs
	@echo "Showing DEV logs..."
	@$(DEV_COMPOSE) logs -f

.PHONY: shell
shell: switch-env-dev ## Start a shell inside the dev 'web' container
	@$(DEV_COMPOSE) ps --status=running --services | grep -q '^web$$' || { echo "web container is not running. Please run 'make up' first." >&2; exit 1; }
	@$(DEV_COMPOSE) exec web /bin/sh

# ==============================================================================
# Production-like Environment Commands
# ==============================================================================

.PHONY: up-prod
up-prod: switch-env-prod ## Build images and start prod-like containers
	@echo "Starting up PROD-like services..."
	@$(PROD_COMPOSE) up -d

.PHONY: down-prod
down-prod: switch-env-prod ## Stop prod-like containers
	@echo "Shutting down PROD-like services..."
	@$(PROD_COMPOSE) down --remove-orphans

# ==============================================================================
# Django Management Commands
# ==============================================================================
.PHONY: makemigrations
makemigrations: ## [DEV] Create migration files
	@$(DEV_COMPOSE) exec web python manage.py makemigrations

.PHONY: migrate
migrate: ## [DEV] Run database migrations
	@echo "Running DEV database migrations..."
	@$(DEV_COMPOSE) exec web python manage.py migrate

.PHONY: superuser
superuser: ## [DEV] Create a Django superuser
	@echo "Creating DEV superuser..."
	@$(DEV_COMPOSE) exec web python manage.py createsuperuser

.PHONY: migrate-prod
migrate-prod: ensure-web-prod ## [PROD] Run database migrations
	@echo "Running PROD-like database migrations..."
	@$(PROD_COMPOSE) exec web python manage.py migrate

.PHONY: superuser-prod
superuser-prod: ensure-web-prod ## [PROD] Create a Django superuser
	@echo "Creating PROD-like superuser..."
	@$(PROD_COMPOSE) exec web python manage.py createsuperuser

# ==============================================================================
# Testing and Code Quality
# ==============================================================================

.PHONY: test
test: ## Run test suite
	@echo "Running tests..."
	@sudo /home/jules/.local/bin/poetry run pytest

.PHONY: lint
lint: ## Run code linting
	@echo "Running ruff linter..."
	@poetry run ruff check .

.PHONY: format
format: ## Format code
	@echo "Formatting code with black..."
	@poetry run black .

.PHONY: format-check
format-check: ## Check code formatting
	@echo "Checking code formatting with black..."
	@poetry run black --check .

# ==============================================================================
# Internal Helper Targets
# ==============================================================================

.PHONY: ensure-web-prod
ensure-web-prod: switch-env-prod
	@$(PROD_COMPOSE) ps --status=running --services | grep -q '^web$$' || make up-prod

# ==============================================================================
# Help
# ==============================================================================

.PHONY: help
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "; OFS=" "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
