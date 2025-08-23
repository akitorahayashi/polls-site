.DEFAULT_GOAL := help

# ==============================================================================
# Docker Commands
# ==============================================================================

.PHONY: setup
setup: ## .env.exampleから.envファイルを安全に作成します（既存の場合はスキップ）
	@echo "Checking for .env file..."
	@if [ ! -f .env.example ]; then \
	  echo "ERROR: .env.exampleが見つかりません" >&2; exit 1; \
	fi
	@if [ -f .env ]; then \
	  echo ".envは既に存在するため作成をスキップします"; \
	else \
	  cp .env.example .env && echo "Created .env from .env.example"; \
	fi

.PHONY: up
up: ## Dockerイメージをビルドし、コンテナをバックグラウンドで起動します
	@echo "Building images and starting containers..."
	@docker compose up --build -d

.PHONY: down
down: ## 実行中のコンテナを停止します
	@echo "Stopping containers..."
	@docker compose down

.PHONY: logs
logs: ## コンテナのログを表示・追跡します
	@echo "Showing logs..."
	@docker compose logs -f

.PHONY: shell
shell: ## 'web'サービスのコンテナ内でシェルを起動します
	@echo "Accessing web container shell..."
	@docker compose exec web /bin/bash

# ==============================================================================
# Django Management Commands
# ==============================================================================

.PHONY: migrate
migrate: ## データベースのマイグレーションを実行します
	@echo "Running database migrations..."
	@docker compose exec web poetry run python manage.py migrate

.PHONY: superuser
superuser: ## Djangoのスーパーユーザーを作成します
	@echo "Creating superuser..."
	@docker compose exec web poetry run python manage.py createsuperuser

# ==============================================================================
# Testing and Code Quality
# ==============================================================================

.PHONY: test
test: ## pytestを使用してテストスイートを実行します
	@echo "Running tests..."
	@docker compose run --rm test

.PHONY: lint
lint: ## ruffを使用してコードのリンティングを実行します
	@echo "Running ruff linter..."
	@docker compose run --rm test poetry run ruff check .

.PHONY: format
format: ## blackを使用してコードをフォーマットします
	@echo "Formatting code with black..."
	@docker compose run --rm test poetry run black .

.PHONY: format-check
format-check: ## blackを使用してコードのフォーマットをチェックします
	@echo "Checking code formatting with black..."
	@docker compose run --rm test poetry run black --check .

# ==============================================================================
# Help
# ==============================================================================

.PHONY: help
help: ## このヘルプメッセージを表示します
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "; OFS=" "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
