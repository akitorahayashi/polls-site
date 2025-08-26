import pytest
from polls.models import Question

# Mark all tests in this file as 'db'
pytestmark = pytest.mark.django_db


def test_db_connection(db_service):
    """
    A simple test to verify that the database container is up and
    that the Django app can connect to it.

    It relies on the `db_service` fixture to set up the database and
    the `django_db` marker to enable database access.
    """
    # The django_db marker handles setting up the test database.
    # If this test runs without throwing an exception, it means the connection
    # and migration setup from conftest.py worked.
    assert True


def test_can_query_model():
    """
    Tests that we can perform a simple query against the database.
    This confirms that tables have been created by migrations.
    """
    # This will fail if migrations haven't run correctly.
    count = Question.objects.count()
    assert count >= 0
