import httpx
import pytest

# Mark all tests in this file as 'e2e'
pytestmark = pytest.mark.e2e

def test_homepage_loads(e2e_services):
    """
    A simple E2E smoke test to verify that the homepage is accessible.
    It uses the `e2e_services` fixture, which provides the base_url.
    """
    base_url = e2e_services

    try:
        response = httpx.get(base_url, follow_redirects=True)
        # A successful page load should return a 200 OK status.
        assert response.status_code == 200
        # Check for some content that should be on the Django homepage.
        assert "Polls" in response.text or "The install worked successfully!" in response.text

    except httpx.RequestError as e:
        pytest.fail(f"Failed to connect to the E2E service at {base_url}. Error: {e}")
