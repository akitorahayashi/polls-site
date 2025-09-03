import os
import subprocess
import time
from typing import Generator

import httpx
import pytest
from dotenv import load_dotenv


@pytest.fixture(scope="session", autouse=True)
def e2e_setup() -> Generator[None, None, None]:
    """
    Manages the lifecycle of the application stack for end-to-end testing.
    """
    load_dotenv(".env")
    web_port = os.getenv("TEST_PORT", "8002")
    # ヘルスチェックURLを新しいエンドポイントに変更
    health_url = f"http://localhost:{web_port}/health/"
    project_name = f"{os.getenv('PROJECT_NAME', 'polls-site')}-test"

    # Determine if sudo should be used
    use_sudo = os.getenv("SUDO") == "true"
    docker_command = ["sudo", "docker"] if use_sudo else ["docker"]

    # Define compose commands
    compose_up_command = docker_command + [
        "compose",
        "-f",
        "docker-compose.yml",
        "-f",
        "docker-compose.test.override.yml",
        "--project-name",
        project_name,
        "up",
        "-d",
        "--build",
    ]
    compose_down_command = docker_command + [
        "compose",
        "-f",
        "docker-compose.yml",
        "-f",
        "docker-compose.test.override.yml",
        "--project-name",
        project_name,
        "down",
        "-v",
        "--remove-orphans",
    ]

    # Start services, ensuring cleanup on failure
    print("\n🚀 Starting E2E services...")
    try:
        subprocess.run(compose_up_command, check=True)

        # Run migrations
        print("\n🏃 Running database migrations...")
        migrate_command = docker_command + [
            "compose",
            "-f",
            "docker-compose.yml",
            "-f",
            "docker-compose.test.override.yml",
            "--project-name",
            project_name,
            "exec",
            "-T",
            "web",
            "python",
            "manage.py",
            "migrate",
            "--noinput",
        ]
        subprocess.run(migrate_command, check=True)

        # Health Check
        start_time = time.time()
        timeout = 120
        is_healthy = False
        while time.time() - start_time < timeout:
            try:
                response = httpx.get(health_url, timeout=5)
                if response.status_code == 200:
                    try:
                        if response.json().get("status") == "ok":
                            print("✅ Application is healthy!")
                            is_healthy = True
                            break
                    except ValueError:
                        # JSON でない応答（起動途中など）
                        pass
                print("⏳ Application not yet healthy, retrying...")
            except (httpx.RequestError, httpx.ConnectError):
                print("⏳ Application not yet healthy, retrying...")
            finally:
                time.sleep(5)

        if not is_healthy:
            log_command = docker_command + [
                "compose",
                "-f",
                "docker-compose.yml",
                "-f",
                "docker-compose.test.override.yml",
                "--project-name",
                project_name,
                "logs",
            ]
            subprocess.run(log_command)
            pytest.fail(f"Application did not become healthy within {timeout} seconds.")

        yield

    finally:
        # Stop services
        print("\n🛑 Stopping E2E services...")
        subprocess.run(compose_down_command, check=False)
