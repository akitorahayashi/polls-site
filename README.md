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
The application will be accessible at the IP address specified by `HOST_IP` in your `.env` file (defaults to `127.0.0.1`).
*   **Polls App**: `http://<HOST_IP>/polls/`
*   **Admin Site**: `http://<HOST_IP>/admin/`

## Environment Configuration

You can customize the application's network settings by creating or editing the `.env` file in the project root. This file is automatically used by `docker compose` when you run `make up`.

-   **`HOST_IP`**: Sets the IP address on the host machine where the application will be accessible.
    -   The default is `127.0.0.1` (localhost), which means the service is only accessible from your local machine. This is recommended for security.
    -   To allow access from other devices on your network (e.g., for testing on a mobile device), you can set this to `0.0.0.0`.
    -   **Note**: The application is served on port `80`. To change this, you must modify the `ports` section in the `docker-compose.yml` file.

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