# syntax=docker/dockerfile:1.7-labs
# ==============================================================================
# Stage 1: Builder
# ==============================================================================
FROM python:3.12-slim-bookworm AS builder

ARG POETRY_VERSION=2.1.4

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
FROM python:3.12-slim-bookworm AS prod-builder

ARG POETRY_VERSION=2.1.4

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
    poetry install --no-root --only main

# ==============================================================================
# Stage 3: Production
# ==============================================================================
FROM python:3.12-slim-bookworm AS production

RUN addgroup --system app && adduser --system --ingroup app appuser

WORKDIR /app
RUN chown appuser:app /app

# Copy virtual environment with correct permissions
COPY --chown=appuser:app --from=prod-builder /app/.venv ./.venv
ENV PATH="/app/.venv/bin:${PATH}"

# Copy application files
COPY --chown=appuser:app manage.py ./
COPY --chown=appuser:app config/ ./config/
COPY --chown=appuser:app entrypoint.sh ./
COPY --chown=appuser:app healthcheck.py ./

RUN chmod +x entrypoint.sh healthcheck.py

USER appuser

EXPOSE 8000

ENV HEALTHCHECK_PATH=/health

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["python", "healthcheck.py"]

ENTRYPOINT ["/app/entrypoint.sh"]