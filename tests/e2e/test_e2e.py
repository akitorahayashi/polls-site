import os

import httpx
import pytest
from dotenv import load_dotenv

# .env.testから環境変数を読み込む
load_dotenv(".env.test")

pytestmark = pytest.mark.asyncio


async def test_polls_index_page_loads():
    """
    E2E test to ensure the main polls index page loads correctly.
    """
    # Arrange
    web_port = os.getenv("WEB_PORT", "8000")
    index_url = f"http://localhost:{web_port}/polls/"

    # Act
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.get(index_url)

    # Assert
    assert response.status_code == 200
    assert "No polls are available." in response.text
    assert "<title>Polls</title>" in response.text
