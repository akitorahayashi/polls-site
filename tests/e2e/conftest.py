import os
import subprocess
import time

import httpx
import pytest
from django.core.management import call_command
from dotenv import dotenv_values


@pytest.fixture(scope="session")
def e2e_services():
    """
    Session-scoped fixture to manage the lifecycle of services for E2E tests.
    It symlinks .env.test to .env, which is created by `make setup`.
    """
    project_name = os.path.basename(os.getcwd()) + "-dev"
    compose_command = ["docker", "compose", "--project-name", project_name]

    # `make setup` creates .env.test, which we read directly.
    env_file = ".env.test"
    if not os.path.exists(env_file):
        pytest.fail(f"'{env_file}' not found. Please run `make setup` first.")

    config = dotenv_values(env_file)
    host_port = config.get("WEB_PORT", "8000")
    base_url = f"http://localhost:{host_port}"

    try:
        # Symlink .env.test to .env for docker-compose, which expects .env
        if os.path.exists(".env"):
            os.remove(".env")
        os.symlink(env_file, ".env")

        # Start services
        print("\n--- Starting E2E services ---")
        up_result = subprocess.run(
            [*compose_command, "up", "--build", "-d"], capture_output=True, text=True
        )

        # Explicitly run migrations after services are up
        print("--- Running migrations for E2E tests ---")
        migrate_result = subprocess.run(
            [*compose_command, "exec", "-T", "web", "python", "manage.py", "migrate"],
            capture_output=True,
            text=True,
        )
        if migrate_result.returncode != 0:
            print(f"--- Migration failed ---\n{migrate_result.stderr}")
            pytest.fail("E2E migrations failed.", pytrace=False)

        # Wait for the web service to be healthy
        print(f"--- Waiting for API at {base_url} to be ready ---")
        max_wait = 120
        start_time = time.time()
        service_ready = False
        while time.time() - start_time < max_wait:
            try:
                response = httpx.get(base_url, follow_redirects=True)
                if response.status_code == 200:
                    print("--- API is ready ---")
                    service_ready = True
                    break
            except httpx.RequestError:
                time.sleep(2)

        if not service_ready:
            print("\n--- E2E service failed to start. Printing diagnostics. ---")
            print(f"--- 'docker compose up' stdout ---\n{up_result.stdout}")
            print(f"--- 'docker compose up' stderr ---\n{up_result.stderr}")

            logs_result = subprocess.run(
                [*compose_command, "logs", "web"], capture_output=True, text=True
            )
            print(
                f"--- 'docker compose logs web' ---\n{logs_result.stdout}\n{logs_result.stderr}"
            )
            pytest.fail(f"E2E services failed to start within {max_wait} seconds.")

        yield base_url

    finally:
        # Stop and clean up services
        print("\n--- Tearing down E2E services ---")
        subprocess.run(
            [*compose_command, "down", "-v", "--remove-orphans"],
            check=True,
            capture_output=True,
            text=True,
        )
        # Clean up the symlink
        if os.path.islink(".env"):
            os.remove(".env")
