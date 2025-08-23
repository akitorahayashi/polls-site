# ==============================================================================
# Builder Stage
# ==============================================================================
# This stage installs all dependencies, including development ones,
# and builds the Python virtual environment.
FROM python:3.12-slim AS builder

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install system dependencies required for building Python packages
# and for poetry installation.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry using the official installer
RUN curl -sSL https://install.python-poetry.org | python3 -

# Add Poetry to the PATH
ENV PATH="/root/.local/bin:$PATH"

WORKDIR /app

# Create a virtual environment in the project directory
RUN poetry config virtualenvs.in-project true

# Copy dependency definition files
COPY poetry.lock pyproject.toml ./

# Install dependencies, --no-root is used because the project is not installed as a package
RUN poetry install --no-interaction --no-root --sync --only main

# ==============================================================================
# Production Stage
# ==============================================================================
# This stage creates the final, lightweight production image.
FROM python:3.12-slim AS production

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install netcat, which is required for the entrypoint script to wait for the database
RUN apt-get update && apt-get install -y --no-install-recommends netcat-openbsd && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create a non-root user and group for security
RUN addgroup --system app && adduser --system --ingroup app appuser

# Copy the virtual environment from the builder stage
COPY --from=builder --chown=appuser:app /app/.venv ./.venv
ENV PATH="/app/.venv/bin:$PATH"

# Copy the entrypoint script and make it executable
COPY --chown=appuser:app entrypoint.sh .
RUN chmod +x ./entrypoint.sh

# Copy application code
COPY --chown=appuser:app manage.py ./
COPY --chown=appuser:app config/ ./config/

# Switch to the non-root user
USER appuser

# Expose the port Gunicorn will run on
EXPOSE 8000

# Set the entrypoint script to be executed when the container starts
ENTRYPOINT ["./entrypoint.sh"]

# Set the default command for the entrypoint
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]