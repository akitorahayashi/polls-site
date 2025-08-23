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

### Local Development

These steps guide you through setting up a local development environment using the Makefile.

**1. Create .env file**

This command copies the example environment file. The default values are suitable for local development.

```bash
make setup
```

**2. Build and Run Containers**

This command builds the Docker images and runs the containers in the background.

```bash
make up
```

**3. Run Database Migrations**

This command executes the database migrations to set up the database schema.

```bash
make migrate
```

**4. Create a Superuser**

This command allows you to create a superuser to access the Django admin site.

```bash
make superuser
```

Follow the prompts to set your username, email, and password.

**5. Access the Application**

The application will be accessible at `http://127.0.0.1` or `http://localhost`.

*   **Polls App**: `http://localhost/polls/`
*   **Admin Site**: `http://localhost/admin/`

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

The first time you deploy to a new server, you may need to run these commands manually on the server to initialize the database and static files:

```bash
# On the production server
docker compose -f docker-compose.prod.yml exec web poetry run python manage.py migrate
docker compose -f docker-compose.prod.yml exec web poetry run python manage.py collectstatic --no-input
docker compose -f docker-compose.prod.yml exec web poetry run python manage.py createsuperuser
```