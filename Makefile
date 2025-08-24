.DEFAULT_GOAL := help

PROJECT_NAME := $(shell basename $(CURDIR))

.PHONY: all
all: help ## Default target

# ==============================================================================
# Docker Commands
# ==============================================================================

.PHONY: setup
setup: ## If .env does not exist, create .env from .env.example
	@[ -f .env.example ] || { echo "ERROR: .env.example not found" >&2; exit 1; }
	@[ -f .env ] && echo ".env already exists. Skipping creation." || { cp .env.example .env && echo "Created .env from .env.example"; }

.PHONY: up
up: ## Build Docker images and start containers in the background
	@echo "Building images and starting containers..."
	@docker compose up --build -d

.PHONY: down
down: ## Stop running containers and remove orphan containers
	@echo "Stopping containers..."
	@docker compose down --remove-orphans

up-prod: ## Start all containers using only docker-compose.yml (ignoring override)
	@echo "Starting up production-like services (ignoring override)..."
	@docker compose -f docker-compose.yml --project-name $(PROJECT_NAME)-prod up -d

down-prod: ## Stop and remove all containers started by up-prod
	@echo "Shutting down production-like services..."
	@docker compose -f docker-compose.yml --project-name $(PROJECT_NAME)-prod down --remove-orphans

.PHONY: clean
clean: ## Completely remove containers, volumes, and orphan resources
	@echo "Cleaning containers, volumes, and orphans..."
	@docker compose down -v --remove-orphans

.PHONY: logs
logs: ## Show and follow container logs
	@echo "Showing logs..."
	@docker compose logs -f

.PHONY: shell
shell: ## Start a shell inside the 'web' service container (must be running)
	@docker compose ps --status=running --services | grep -q '^web$$' || { echo "web container is not running. Please run 'make up' first." >&2; exit 1; }
	@docker compose exec web /bin/sh

# ==============================================================================
# Django Management Commands
# ==============================================================================
.PHONY: makemigrations
makemigrations: ensure-web ## Create migration files when models are changed
	@docker compose exec web python manage.py makemigrations

.PHONY: migrate
migrate: ensure-web ## Manually run database migrations (usually run automatically on startup)
	@echo "Running manual database migrations..."
	@docker compose exec web python manage.py migrate

.PHONY: superuser
superuser: ensure-web ## Create a Django superuser (interactive, starts container if needed)
	@echo "Creating superuser..."
	@docker compose exec web python manage.py createsuperuser

# ==============================================================================
# Testing and Code Quality
# ==============================================================================

.PHONY: test
test: ## Run test suite using pytest
	@echo "Running tests..."
	@docker compose run --rm test

.PHONY: lint
lint: ## Run code linting using ruff
	@echo "Running ruff linter..."
	@docker compose run --rm test poetry run ruff check .

.PHONY: format
format: ## Format code using black
	@echo "Formatting code with black..."
	@docker compose run --rm test poetry run black .

.PHONY: format-check
format-check: ## Check code formatting using black
	@echo "Checking code formatting with black..."
	@docker compose run --rm test poetry run black --check .

# ==============================================================================
# Internal Helper Targets
# ==============================================================================

.PHONY: ensure-web
ensure-web:
	@docker compose ps --status=running --services | grep -q '^web$$' || docker compose up -d

# ==============================================================================
# Help
# ==============================================================================

.PHONY: help
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "; OFS=" "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
