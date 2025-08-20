## Overview

This repository is for deploying the Django polls app.

## Tech Stack

*   **Backend**: Django
*   **Database**: PostgreSQL
*   **Web Server**: Nginx, Gunicorn
*   **Containerization**: Docker, Docker Compose

## Deployment Steps

### 1. Create .env file

Create a `.env` file in the project's root directory.

```bash
$ touch .env
```

Add the following environment variables to the `.env` file. You can modify the values as needed.

```
# .env

# PostgreSQL settings
POSTGRES_DB=polls_db
POSTGRES_USER=polls_user
POSTGRES_PASSWORD=polls_password

# Host IP for Nginx
# If not set, defaults to 127.0.0.1 (localhost)
# Example: HOST_IP=192.168.1.10
HOST_IP=127.0.0.1
```

### 2. Build and Run Containers

Build the Docker images and run the containers in the background.

```bash
$ docker-compose up --build -d
```

### 3. Run Database Migrations

Execute the database migrations.

```bash
$ docker-compose exec web poetry run python manage.py migrate
```

### 4. Collect Static Files

Collect static files so they can be served by Nginx.

```bash
$ docker-compose exec web poetry run python manage.py collectstatic --no-input
```

### 5. Create a Superuser

Create a superuser to access the Django admin site.

```bash
$ docker-compose exec web poetry run python manage.py createsuperuser
```

Follow the prompts to set your username, email, and password.

### 6. Access the Application

The application will be accessible at the IP address specified by `HOST_IP`. If `HOST_IP` is not set, it will be available at `http://127.0.0.1` or `http://localhost`.

*   Polls App: `http://<HOST_IP>/polls/`
*   Admin Site: `http://<HOST_IP>/admin/`
