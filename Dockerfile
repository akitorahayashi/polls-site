# syntax=docker/dockerfile:1.7-labs
# ==============================================================================
# Stage 1: Builder
# ==============================================================================
FROM python:3.12-slim-bullseye AS builder

ARG POETRY_VERSION=1.8.2

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_CACHE_DIR=/tmp/poetry_cache \
    PATH="/root/.local/bin:${PATH}"

WORKDIR /app

RUN --mount=type=cache,target=/root/.cache \
    pip install pipx && \
    pipx ensurepath && \
    pipx install "poetry==${POETRY_VERSION}"

COPY pyproject.toml poetry.lock ./

RUN --mount=type=cache,target=/tmp/poetry_cache \
    poetry config virtualenvs.in-project true && \
    poetry install --no-root

# ==============================================================================
# Stage 2: Prod-Builder
# ==============================================================================
FROM python:3.12-slim-bullseye AS prod-builder

ARG POETRY_VERSION=1.8.2

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_CACHE_DIR=/tmp/poetry_cache \
    PATH="/root/.local/bin:${PATH}"

WORKDIR /app

RUN --mount=type=cache,target=/root/.cache \
    pip install pipx && \
    pipx ensurepath && \
    pipx install "poetry==${POETRY_VERSION}"

COPY pyproject.toml poetry.lock ./

RUN --mount=type=cache,target=/tmp/poetry_cache \
    poetry config virtualenvs.in-project true && \
    poetry install --no-root

# ==============================================================================
# Stage 3: Production
# ==============================================================================
FROM python:3.12-slim-bullseye AS production

RUN addgroup --system app && adduser --system --ingroup app appuser

WORKDIR /app
RUN chown appuser:app /app

# 仮想環境をコピー
COPY --from=prod-builder /app/.venv ./.venv
ENV PATH="/app/.venv/bin:${PATH}"

# 必要なファイルのみコピー
COPY --chown=appuser:app manage.py ./
COPY --chown=appuser:app config/ ./config/
COPY --chown=appuser:app entrypoint.sh ./

RUN chmod +x entrypoint.sh

USER appuser

EXPOSE 8000

ENV HEALTHCHECK_PATH=/health

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import sys, os, urllib.request; sys.exit(0) if urllib.request.urlopen(f'http://localhost:8000{os.environ.get('HEALTHCHECK_PATH')}').getcode() == 200 else sys.exit(1)"

ENTRYPOINT ["/app/entrypoint.sh"]