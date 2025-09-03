import httpx
import pytest

pytestmark = pytest.mark.asyncio


async def test_polls_index_page_loads(page_url: str):
    """メインの投票インデックスページが正しく読み込まれることを確認するE2Eテスト。"""
    index_url = f"{page_url}polls/"

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.get(index_url)

    assert response.status_code == 200
    assert "framework?" in response.text or "No polls are available." in response.text
    assert "<title>Polls</title>" in response.text
