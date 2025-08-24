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

These steps guide you through setting up a local development environment.

### 1. Create .env file
This command copies the example environment file. The default values are suitable for local development.
```bash
make setup
```

### 2. Build and Run Containers
This command builds the Docker images and runs the containers in the background. Thanks to the `entrypoint.sh` script, it also automatically applies any pending database migrations upon startup.
```bash
make up
```

### 3. Create a Superuser (Optional)
This command allows you to create a superuser to access the Django admin site.
```bash
make superuser
```
Follow the prompts to set your username, email, and password.

### 4. Access the Application

The application's access URL depends on the environment you are running.

-   **Development (`make up`)**:
    The Django development server is exposed directly. The port is controlled by the `DEV_PORT` variable in your `.env` file (defaults to `8000`).
    -   **Polls App**: `http://<DEV_BIND_HOST>:<DEV_PORT>/polls/`
    -   **Admin Site**: `http://<DEV_BIND_HOST>:<DEV_PORT>/admin/`
    -   Default URL: `http://127.0.0.1:8000/polls/`

-   **Production-like (`make up-prod`)**:
    The Nginx server is exposed. The port is controlled by the `PROD_PORT` variable in your `.env` file (defaults to `58080`).
    -   **Polls App**: `http://<PROD_HOST_IP>:<PROD_PORT>/polls/`
    -   **Admin Site**: `http://<PROD_HOST_IP>:<PROD_PORT>/admin/`
    -   Default URL: `http://127.0.0.1:58080/polls/`

## Environment Configuration

You can customize the application's network settings by creating or editing the `.env` file in the project root. This file is automatically used by `docker compose`.

-   **`DEV_PORT`**: Sets the port for the development server (`make up`). Defaults to `8000`.
-   **`DEV_BIND_HOST`**: Binds the development server to a specific host. Defaults to `127.0.0.1` (localhost). Change to `0.0.0.0` to allow access from other devices on your network.
-   **`PROD_PORT`**: Sets the public-facing port for the Nginx server in the production-like environment (`make up-prod`). Defaults to `58080`. Using a high port number avoids conflicts with common services and removes the need for root privileges.
-   **`PROD_HOST_IP`**: Sets the IP for the Nginx server. Defaults to `127.0.0.1`.

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