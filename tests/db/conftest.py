import os
import subprocess
import time

import psycopg2
import pytest
from django.core.management import call_command
from dotenv import dotenv_values


@pytest.fixture(scope="session")
def db_service():
    """
    Session-scoped fixture to manage a standalone DB service using docker-compose.
    It symlinks .env.test to .env, which is created by `make setup`.
    """
    project_name = os.path.basename(os.getcwd()) + "-dev"
    compose_command = ["docker", "compose", "--project-name", project_name]

    # `make setup` creates .env.test, which we read directly.
    env_file = ".env.test"
    if not os.path.exists(env_file):
        pytest.fail(f"'{env_file}' not found. Please run `make setup` first.")

    config = dotenv_values(env_file)

    try:
        # Symlink .env.test to .env for docker-compose, which expects .env
        if os.path.exists(".env"):
            os.remove(".env")
        os.symlink(env_file, ".env")

        # Start only the db service
        print("\n--- Starting DB service for tests ---")
        subprocess.run(
            [*compose_command, "up", "-d", "db"],
            check=True, capture_output=True, text=True
        )

        # Wait for the database to be ready
        print("--- Waiting for DB service to be ready ---")
        max_wait = 60
        start_time = time.time()
        # Read connection details from the loaded config
        db_host = config.get("DB_HOST", "localhost")
        db_port = config.get("DB_PORT", "5432")
        db_name = config.get("POSTGRES_DB", "testdb")
        db_user = config.get("POSTGRES_USER", "user")
        db_password = config.get("POSTGRES_PASSWORD", "password")
        database_url = f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"

        while time.time() - start_time < max_wait:
            try:
                conn = psycopg2.connect(database_url)
                conn.close()
                print("--- DB service is ready ---")
                break
            except psycopg2.OperationalError:
                time.sleep(1)
        else:
            pytest.fail(f"DB service failed to start within {max_wait} seconds.")

        os.environ["DATABASE_URL"] = database_url
        yield

    finally:
        # Stop the db service
        print("\n--- Tearing down DB service ---")
        subprocess.run(
            [*compose_command, "down", "-v"],
            check=True, capture_output=True, text=True
        )
        # Clean up the symlink
        if os.path.islink(".env"):
            os.remove(".env")

@pytest.fixture(scope="session")
def django_db_setup(django_db_setup, django_db_blocker, db_service):
    """
    Override the default django_db_setup to ensure our service is running
    and migrations are applied.
    """
    with django_db_blocker.unblock():
        call_command("migrate")
