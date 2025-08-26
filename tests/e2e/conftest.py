import os
import subprocess
import time

import httpx
import pytest


@pytest.fixture(scope="session")
def e2e_services():
    """
    Session-scoped fixture to manage the lifecycle of services for E2E tests.
    This fixture replicates the logic from the Makefile's 'test' target.
    """
    # Use the same project name logic as the Makefile
    project_name = os.path.basename(os.getcwd()) + "-dev"
    compose_command = [
        "docker",
        "compose",
        "--project-name",
        project_name,
        "--env-file",
        ".env.test",
    ]

    # Define HOST_PORT, default to 8000 if not set
    host_port = os.environ.get("HOST_PORT", "8000")
    base_url = f"http://localhost:{host_port}"

    try:
        # Start services
        print("\n--- Starting E2E services ---")
        # Ensure clean state before starting
        subprocess.run(
            [*compose_command, "down", "-v", "--remove-orphans"],
            check=True,
            capture_output=True,
            text=True,
        )
        subprocess.run(
            [*compose_command, "up", "--build", "-d"],
            check=True,
            capture_output=True,
            text=True,
        )

        # Wait for the web service to be healthy
        print(f"--- Waiting for API at {base_url} to be ready ---")
        max_wait = 120  # 2 minutes max wait
        start_time = time.time()
        while time.time() - start_time < max_wait:
            try:
                # In Django, the root URL might redirect, but it should at least respond.
                response = httpx.get(base_url, follow_redirects=True)
                if response.status_code == 200:
                    print("--- API is ready ---")
                    break
            except httpx.RequestError:
                time.sleep(2)  # Wait before retrying
        else:
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
