import os
import time
from pathlib import Path
from typing import Generator

import pytest
import requests
from dotenv import load_dotenv
from testcontainers.compose import DockerCompose


# Override pytest-django's autouse fixture to disable mail.outbox clearing for e2e tests
@pytest.fixture(scope="function", autouse=True)
def _dj_autoclear_mailbox():
    """Override pytest-django's autoclear mailbox fixture to disable it for e2e tests."""
    # Do nothing - we don't need mail.outbox clearing in e2e tests with external containers
    pass


def _is_service_ready(url: str, expected_status: int = 200) -> bool:
    """HTTPサービスがリクエストを受け付ける準備ができているかを確認します。"""
    try:
        response = requests.get(url, timeout=5)
        return response.status_code == expected_status
    except requests.exceptions.ConnectionError:
        return False


def _wait_for_service(url: str, timeout: int = 120, interval: int = 5) -> None:
    """HTTPサービスが準備完了になるまでタイムアウト付きで待機します。"""
    start_time = time.time()
    while time.time() - start_time < timeout:
        if _is_service_ready(url):
            return
        time.sleep(interval)
    raise TimeoutError(
        f"Service at {url} did not become ready within {timeout} seconds"
    )


@pytest.fixture(scope="session")
def app_container() -> Generator[DockerCompose, None, None]:
    """Docker Composeを介して完全に実行中のアプリケーションスタックを提供します。"""
    load_dotenv(".env")
    compose_files = [
        "docker-compose.yml",
        "docker-compose.test.override.yml",
    ]

    project_root = Path(__file__).parent.parent.parent
    compose_file_paths = [str(project_root / file) for file in compose_files]

    with DockerCompose(
        str(project_root),
        compose_file_name=compose_file_paths,
        build=True,
    ) as compose:
        host_port = os.getenv("TEST_PORT", "8002")
        assert (
            compose.get_container("nginx") is not None
        ), "nginx container could not be found."

        health_check_url = f"http://localhost:{host_port}/health/"

        _wait_for_service(health_check_url, timeout=120, interval=5)

        compose.host_port = host_port
        yield compose


@pytest.fixture(scope="session")
def page_url(app_container: DockerCompose) -> str:
    """実行中のアプリケーションのベースURLを返します。"""
    host_port = app_container.host_port
    return f"http://localhost:{host_port}/"
