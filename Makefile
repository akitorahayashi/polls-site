.DEFAULT_GOAL := help

.PHONY: all
all: help ## 既定のターゲット（ヘルプ表示）

# ==============================================================================
# Docker Commands
# ==============================================================================

.PHONY: setup
setup: ## .env.exampleから.envファイルを安全に作成します（既存の場合はスキップ）
	@[ -f .env.example ] || { echo "ERROR: .env.exampleが見つかりません" >&2; exit 1; }
	@[ -f .env ] && echo ".envは既に存在するため作成をスキップします" || { cp .env.example .env && echo "Created .env from .env.example"; }

.PHONY: up
up: ## Dockerイメージをビルドし、コンテナをバックグラウンドで起動します
	@echo "Building images and starting containers..."
	@docker compose up --build -d

.PHONY: down
down: ## 実行中のコンテナを停止し、孤立コンテナを削除します
	@echo "Stopping containers..."
	@docker compose down --remove-orphans

.PHONY: clean
clean: ## コンテナ、ボリューム、孤立リソースを完全に削除します
	@echo "Cleaning containers, volumes, and orphans..."
	@docker compose down -v --remove-orphans

.PHONY: logs
logs: ## コンテナのログを表示・追跡します
	@echo "Showing logs..."
	@docker compose logs -f

.PHONY: shell
shell: ## 'web'サービスのコンテナ内でシェルを起動します（要起動）
	@docker compose ps --status=running --services | grep -q '^web$$' || { echo "webコンテナが起動していません。'make up' を先に実行してください。" >&2; exit 1; }
	@docker compose exec web /bin/sh

# ==============================================================================
# Django Management Commands
# ==============================================================================

.PHONY: migrate
migrate: ensure-web ## 手動でデータベースのマイグレーションを実行します（通常は起動時に自動実行されます）
	@echo "Running manual database migrations..."
	@docker compose exec web python manage.py migrate

.PHONY: superuser
superuser: ensure-web ## Djangoのスーパーユーザーを作成します（対話モード、必要ならコンテナを起動）
	@echo "Creating superuser..."
	@docker compose exec web python manage.py createsuperuser

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
# Internal Helper Targets
# ==============================================================================

.PHONY: ensure-web
ensure-web:
	@docker compose ps --status=running --services | grep -q '^web$$' || docker compose up -d

# ==============================================================================
# Help
# ==============================================================================

.PHONY: help
help: ## このヘルプメッセージを表示します
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "; OFS=" "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
