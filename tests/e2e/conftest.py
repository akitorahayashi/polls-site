import os
import subprocess
import time
from typing import Generator

import httpx
import pytest
from dotenv import load_dotenv


# Override pytest-django's autouse fixture to disable mail.outbox clearing for e2e tests
@pytest.fixture(scope="function", autouse=True)
def _dj_autoclear_mailbox():
    """Override pytest-django's autoclear mailbox fixture to disable it for e2e tests."""
    # Do nothing - we don't need mail.outbox clearing in e2e tests with external containers
    pass


@pytest.fixture(scope="session")
def docker_server() -> Generator[str, None, None]:
    """
    Sets up a live application stack using Docker Compose for end-to-end testing.

    This fixture:
    1. Starts Docker Compose services using the test configuration
    2. Waits for the application to become healthy
    3. Yields the base URL for tests
    4. Cleans up containers after tests complete
    """
    # Load environment variables
    load_dotenv(".env")

    # Get configuration from environment
    project_name = os.getenv("PROJECT_NAME", "polls-site")
    test_port = os.getenv("TEST_PORT", "8002")
    web_host = os.getenv("WEB_HOST", "127.0.0.1")

    # Docker Compose command with test configuration
    compose_cmd = [
        "docker",
        "compose",
        "-f",
        "docker-compose.yml",
        "-f",
        "docker-compose.test.override.yml",
        "--project-name",
        f"{project_name}-test",
    ]

    base_url = f"http://{web_host}:{test_port}"
    health_url = f"{base_url}/health/"

    try:
        print("\nStarting Docker Compose services for testing...")

        # Start containers
        subprocess.run(
            compose_cmd + ["up", "-d", "--build"],
            check=True,
            capture_output=True,
            text=True,
        )

        print(f"⏳ Waiting for application to be ready at {health_url}...")

        # Wait for application to be healthy
        start_time = time.time()
        timeout = 120  # Increased timeout for Docker startup
        is_healthy = False

        # Improve healthcheck loop to sleep after each attempt and catch general exceptions
        while time.time() - start_time < timeout:
            try:
                response = httpx.get(health_url, timeout=10)
                if (
                    response.status_code == 200
                    and response.json().get("status") == "ok"
                ):
                    print("✅ Application is healthy!")
                    is_healthy = True
                    break
                else:
                    print(
                        f"⏳ Waiting for application... (status: {response.status_code})"
                    )
            except Exception as e:
                print(f"⏳ Waiting for application... ({e.__class__.__name__})")
            # Sleep between attempts to avoid tight loop
            time.sleep(3)

        if not is_healthy:
            # Get logs for debugging
            print("❌ Application failed to start. Getting logs...")
            try:
                logs_result = subprocess.run(
                    compose_cmd + ["logs"],
                    check=True,
                    capture_output=True,
                    text=True,
                    timeout=30,
                )
                print("--- Docker Compose Logs ---")
                print(logs_result.stdout)
                if logs_result.stderr:
                    print("--- Docker Compose Errors ---")
                    print(logs_result.stderr)
            except subprocess.TimeoutExpired:
                print("Timeout while getting logs")

            pytest.fail(
                f"Application did not become healthy within {timeout} seconds. "
                f"Check Docker Compose logs above."
            )

        print(f"🚀 E2E test environment ready at {base_url}")
        yield base_url

    finally:
        print("\n🛑 Stopping Docker Compose services...")
        try:
            subprocess.run(
                compose_cmd + ["down", "--remove-orphans"],
                check=True,
                capture_output=True,
                text=True,
                timeout=60,
            )
            print("✅ Docker Compose services stopped successfully")
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            print(f"⚠️ Warning: Failed to stop some containers: {e}")


@pytest.fixture(scope="session")
def page_url(docker_server: str) -> str:
    """
    Returns the base URL of the docker server.
    """
    return f"{docker_server}/"
