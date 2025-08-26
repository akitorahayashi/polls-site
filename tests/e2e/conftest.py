import os
import subprocess
import time
import pytest
import httpx

@pytest.fixture(scope="session")
def e2e_services():
    """
    Session-scoped fixture to manage the lifecycle of services for E2E tests.
    It symlinks .env.test to .env, which is created by `make setup`.
    """
    project_name = os.path.basename(os.getcwd()) + "-dev"
    compose_command = ["docker", "compose", "--project-name", project_name]

    # `make setup` creates .env.test, but docker-compose expects .env
    if not os.path.exists(".env.test"):
        pytest.fail("'.env.test' not found. Please run `make setup` first.")

    host_port = os.environ.get("HOST_PORT", "8000")
    base_url = f"http://localhost:{host_port}"

    try:
        # Symlink .env.test to .env for docker-compose
        if os.path.exists(".env"):
            os.remove(".env")
        os.symlink(".env.test", ".env")

        # Start services
        print("\n--- Starting E2E services ---")
        subprocess.run(
            [*compose_command, "up", "--build", "-d"],
            check=True, capture_output=True, text=True
        )

        # Wait for the web service to be healthy
        print(f"--- Waiting for API at {base_url} to be ready ---")
        max_wait = 120
        start_time = time.time()
        while time.time() - start_time < max_wait:
            try:
                response = httpx.get(base_url, follow_redirects=True)
                if response.status_code == 200:
                    print("--- API is ready ---")
                    break
            except httpx.RequestError:
                time.sleep(2)
        else:
            pytest.fail(f"E2E services failed to start within {max_wait} seconds.")

        yield base_url

    finally:
        # Stop and clean up services
        print("\n--- Tearing down E2E services ---")
        subprocess.run(
            [*compose_command, "down", "-v", "--remove-orphans"],
            check=True, capture_output=True, text=True
        )
        # Clean up the symlink
        if os.path.islink(".env"):
            os.remove(".env")
