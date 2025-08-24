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

These steps guide you through setting up a local development environment. The `Makefile` is designed to automatically manage environment configurations, providing a seamless development experience.

### 1. Initial Setup
This command creates your local environment files, `.env.dev` and `.env.prod`, from their respective templates (`.env.dev.example`, `.env.prod.example`). You only need to run this once.
```bash
make setup
```
-   `.env.dev`: Used for local development (`make up`). The default values are pre-configured for this purpose.
-   `.env.prod`: Used for production-like testing (`make up-prod`). **Before deploying to a real production environment, you must review and edit the values in this file.**

### 2. Build and Run Containers
This command builds the Docker images and runs the containers for the **development environment**. It automatically selects the `.env.dev` configuration.
```bash
make up
```

To start a **production-like environment**, use:
```bash
make up-prod
```
This command automatically uses the `.env.prod` configuration.

### 3. Create a Superuser (Optional)
This command allows you to create a superuser to access the Django admin site. It runs in the development environment.
```bash
make superuser
```
Follow the prompts to set your username, email, and password.

### 4. Access the Application

The application's access URL depends on the environment you are running. The `Makefile` automatically switches the underlying `.env` file for you.

-   **Development (`make up`)**:
    The Django development server is exposed. The port is controlled by the `DEV_PORT` variable in your `.env.dev` file (defaults to `8000`).
    -   Default URL: `http://127.0.0.1:8000/polls/`

-   **Production-like (`make up-prod`)**:
    The Nginx server is exposed. The port is controlled by the `PROD_PORT` variable in your `.env.prod` file (defaults to `58080`).
    -   Default URL: `http://127.0.0.1:58080/polls/`

## Environment Configuration

Environment settings are managed through two files:
-   **`.env.dev`**: For the development environment. Customize `DEV_PORT` or `DEV_BIND_HOST` here.
-   **`.env.prod`**: For the production environment. Customize `PROD_PORT` and other production-specific settings here.

The `Makefile` targets (`up`, `down`, `test`, etc.) automatically create a symbolic link named `.env` that points to the correct file (`.env.dev` or `.env.prod`) based on the command you run. This ensures that Docker Compose always loads the appropriate configuration without needing manual intervention, simplifying the development workflow.

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