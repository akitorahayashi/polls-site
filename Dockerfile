# Stage 1: base
# システムレベルの依存関係とPython環境の基本設定
FROM python:3.12-slim-bullseye AS base

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN pip install poetry

# Stage 2: builder
# 開発用ライブラリを含むすべてのPython依存関係をインストール
FROM base AS builder

WORKDIR /app

COPY poetry.lock pyproject.toml ./

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN poetry config virtualenvs.in-project true \
    && poetry install --no-interaction --no-root --sync

ENV PATH="/app/.venv/bin:$PATH"

# Stage 3: production
# 実行に必要なものだけを含む軽量な本番イメージ
FROM base AS production

WORKDIR /app

# 非rootユーザーを作成し、パーミッションを設定
RUN addgroup --system app && adduser --system --ingroup app appuser
RUN chown -R appuser:app /app

# 仮想環境をコピー
COPY --from=builder /app/.venv ./.venv
ENV PATH="/app/.venv/bin:$PATH"

# アプリケーションの実行に必要なファイルのみをコピー
COPY --chown=appuser:app manage.py ./
COPY --chown=appuser:app config/ ./config/

# 非rootユーザーに切り替え
USER appuser

EXPOSE 8000

CMD ["/app/.venv/bin/gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]