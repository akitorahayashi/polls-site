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
This one-time command creates your local environment files, `.env.dev` and `.env.prod`, from the single `.env.example` template.
```bash
make setup
```
-   **`.env.dev`**: Your personal configuration for local development. You can customize variables here. This file is **tracked by Git** to ensure a consistent starting point for all developers.
-   **`.env.prod`**: Configuration for production. This file is **NOT tracked by Git** and must be created and managed securely in your production environment.

After setup, you can customize the values in `.env.dev` and `.env.prod`. For example, to run production on a different port:
```sh
# in .env.prod
WEB_PORT=58080
```

### 2. Build and Run Containers
To start the **development environment**, run:
```bash
make up
```
This command automatically uses the `.env.dev` configuration and brings up the services with development-specific settings, like hot-reloading.

To start a **production-like environment**, use:
```bash
make up-prod
```
This command uses the `.env.prod` configuration and runs the services as they would in production (e.g., without debug mode or code mounting).

### 3. Access the Application
In both development and production-like environments, **Nginx is the single entry point**. The application's access URL is determined by the variables in the corresponding `.env` file that `make` automatically selects for you.

-   **Development (`make up`)**: Access via `http://${WEB_HOST_BIND_IP}:${WEB_PORT}/polls/`.
    -   Uses values from `.env.dev` (e.g., `http://127.0.0.1:8000/polls/`).
-   **Production-like (`make up-prod`)**: Access via `http://${WEB_HOST_BIND_IP}:${WEB_PORT}/polls/`.
    -   Uses values from `.env.prod` (e.g., `http://127.0.0.1:58080/polls/`).

## Environment Configuration
This project follows the **DRY (Don't Repeat Yourself)** principle.

-   **Variable Keys**: Defined once in `.env.example`. This is the single source of truth for *what* can be configured.
-   **Variable Values**: Set in `.env.dev` (for development) and `.env.prod` (for production). This separates the configuration *values* from the service definitions.
-   **Service Definitions**:
    -   `docker-compose.yml`: Contains the base configuration for all environments. It uses unified variables like `${WEB_PORT}`.
    -   `docker-compose.override.yml`: Contains **development-only** modifications (e.g., mounting source code, changing the run command).
-   **Makefile Automation**: The `Makefile` automatically creates a symlink named `.env` pointing to either `.env.dev` or `.env.prod` depending on the target (`up` vs `up-prod`). This makes the process seamless and removes the need for manual environment setup.

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