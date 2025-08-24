# Django Polls Site

## Overview

This repository contains a Django polls application, fully containerized with Docker and set up with a CI/CD pipeline for automated builds and deployments.

## Tech Stack

*   **Backend**: Django
*   **Database**: PostgreSQL
*   **Web Server**: Nginx, Gunicorn
*   **Containerization**: Docker, Docker Compose
*   **CI/CD**: GitHub Actions

## Makefile

This project uses a `Makefile` to simplify common development and CI/CD tasks. The Makefile provides a set of easy-to-use commands for building, running, testing, and managing the application.

To see a full list of available commands, run:

```bash
make help
```

## Getting Started

This project uses a streamlined and robust environment configuration based on a **single source of truth** (`.env.example`). The `Makefile` automates the setup, providing a seamless and consistent developer experience.

### 1. Initial Setup
This one-time command creates your local environment files from the single `.env.example` template.
```bash
make setup
```
This creates:
*   **`.env.dev`**: Your personal configuration for local development. This file is **tracked by Git** to ensure a consistent starting point for all developers.
*   **`.env.prod`**: Configuration for production. This file is **NOT tracked by Git** and must be created and managed securely in your production environment.

After setup, you can customize the values in the generated files. For example, to run production on a different port, edit `.env.prod`:
```sh
# in .env.prod
WEB_PORT=58080

# To apply the change, restart the containers:
# make down-prod && make up-prod
```

### 2. Build and Run Containers
*   **Development**: `make up`
*   **Production-like**: `make up-prod`

### 3. Access the Application
In both environments, **Nginx is the single entry point**. The access URL depends on the `WEB_HOST_BIND_IP` and `WEB_PORT` variables in the active `.env` file.
*   **Development (`make up`)** uses values from `.env.dev` (e.g., `http://127.0.0.1:8000/polls/`).
*   **Production-like (`make up-prod`)** uses values from `.env.prod` (e.g., `http://127.0.0.1:58080/polls/`).

## Environment Configuration
This project follows the **DRY (Don't Repeat Yourself)** principle.

*   **Variable Keys**: Defined once in `.env.example`. This is the single source of truth for *what* can be configured.
*   **Variable Values**: Set in `.env.dev` and `.env.prod`. This separates the configuration *values* from the service definitions.
*   **Service Definitions**:
    *   `docker-compose.yml`: Contains the base configuration for all environments. It uses unified variables like `${WEB_PORT}`.
    *   `docker-compose.override.yml`: Contains **development-only** modifications (e.g., mounting source code, changing the run command).
*   **Makefile Automation**: The `Makefile` automatically creates a symbolic link named `.env` pointing to either `.env.dev` or `.env.prod` depending on the target (`up` vs `up-prod`). This makes the process seamless and removes the need for manual environment setup. Note that this `.env` symlink is intentionally not tracked by Git.

## Security and Environment Variables
*   **`.env.dev`**: This file is tracked by Git and should **NEVER** contain real secrets or production credentials. It is intended for non-sensitive, local-only, or dummy values that ease onboarding for new developers.
*   **`.env.prod`**: This file is **NOT** tracked by Git and is where all production secrets and credentials must be stored. It must be managed securely in the production environment.
*   **Recommendation**: To prevent accidental commits of secrets, consider using a tool like `git-secret` or pre-commit hooks that scan for sensitive data before committing.

## Testing and Code Quality

### Testing
To run the test suite, execute the following command. This will start a dedicated test database and run the tests against it.
```bash
make test
```

### Code Quality
To lint and format your code, you can use the following commands:
*   **Linting**: `make lint`
*   **Formatting**: `make format`
*   **Check Formatting**: `make format-check`

## Makefile Commands

Here is a list of all available commands in the Makefile:

| Command        | Description                                       |
|----------------|---------------------------------------------------|
| `setup`        | Create .env file from .env.example                |
| `up`           | Build images and start containers                 |
| `down`         | Stop containers                                   |
| `logs`         | Show container logs                               |
| `shell`        | Access the web container shell                    |
| `migrate`      | Run database migrations                           |
| `superuser`    | Create a superuser                                |
| `test`         | Run tests                                         |
| `lint`         | Lint code with ruff                               |
| `format`       | Format code with black                            |
| `format-check` | Check code formatting with black                  |

## Deployment

This project is configured for semi-automated deployments to a production environment using GitHub Actions.

### Workflow

1.  **Build & Push**: Pushing to the `main` branch automatically triggers the `create_docker_image` workflow. This builds a new production-ready Docker image and pushes it to the GitHub Container Registry (ghcr.io).

2.  **Deploy**: To deploy the new version, manually trigger the `Deploy to Production` workflow from the Actions tab in your GitHub repository. This will connect to the production server, pull the latest image from ghcr.io, and restart the services.

### Initial Server Setup

The first time you deploy to a new server, you may need to run these commands manually to initialize the database and static files. On a typical production server, only the base `docker-compose.yml` would be present, so no `-f` flag is required.

The `production` stage of the Docker image does not include Poetry, so commands must be run directly with `python`.

```bash
# On the production server
docker compose exec web python manage.py migrate
docker compose exec web python manage.py collectstatic --no-input
docker compose exec web python manage.py createsuperuser
```