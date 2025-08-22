# Django Polls Site

## Overview

This repository contains a Django polls application, fully containerized with Docker and set up with a CI/CD pipeline for automated builds and deployments.

## Tech Stack

*   **Backend**: Django
*   **Database**: PostgreSQL
*   **Web Server**: Nginx, Gunicorn
*   **Containerization**: Docker, Docker Compose
*   **CI/CD**: GitHub Actions

## Getting Started

### Local Development

These steps guide you through setting up a local development environment.

**1. Create .env file**

Copy the example environment file. The default values are suitable for local development.

```bash
cp .env.example .env
```

**2. Build and Run Containers**

Build the Docker images and run the containers in the background.

```bash
docker compose up --build -d
```

**3. Run Database Migrations**

Execute the database migrations to set up the database schema.

```bash
docker compose exec web poetry run python manage.py migrate
```

**4. Create a Superuser**

Create a superuser to access the Django admin site.

```bash
docker compose exec web poetry run python manage.py createsuperuser
```

Follow the prompts to set your username, email, and password.

**5. Access the Application**

The application will be accessible at `http://127.0.0.1` or `http://localhost`.

*   **Polls App**: `http://localhost/polls/`
*   **Admin Site**: `http://localhost/admin/`

### Testing

To run the test suite, execute the following command. This will start a dedicated test database and run the tests against it.

```bash
docker compose run --rm test
```

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