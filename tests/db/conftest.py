import os
import subprocess
import time
import pytest
import psycopg2
from django.core.management import call_command

@pytest.fixture(scope="session")
def db_service():
    """
    Session-scoped fixture to manage a standalone DB service using docker-compose.
    It symlinks .env.test to .env, which is created by `make setup`.
    """
    project_name = os.path.basename(os.getcwd()) + "-dev"
    compose_command = ["docker", "compose", "--project-name", project_name]

    # `make setup` creates .env.test, but docker-compose expects .env
    if not os.path.exists(".env.test"):
        pytest.fail("'.env.test' not found. Please run `make setup` first.")

    try:
        # Symlink .env.test to .env for docker-compose
        if os.path.exists(".env"):
            os.remove(".env")
        os.symlink(".env.test", ".env")

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
        # Read connection details from the env file for psycopg2
        db_host = os.environ.get("DB_HOST", "localhost")
        db_port = os.environ.get("DB_PORT", "5432")
        db_name = os.environ.get("POSTGRES_DB", "testdb")
        db_user = os.environ.get("POSTGRES_USER", "user")
        db_password = os.environ.get("POSTGRES_PASSWORD", "password")
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
