import httpx
import pytest

pytestmark = pytest.mark.asyncio


async def test_polls_index_page_loads(page_url: str):
    """
    E2E test to ensure the main polls index page loads correctly.
    """
    # Arrange
    index_url = f"{page_url}polls/"

    # Act
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.get(index_url)

    # Assert
    assert response.status_code == 200
    # Check for basic polls page structure (works whether polls exist or not)
    assert "framework?" in response.text or "No polls are available." in response.text
    assert "<title>Polls</title>" in response.text
