import os

import pytest
from testcontainers.postgres import PostgresContainer


# Run this code before all tests
@pytest.fixture(scope="session", autouse=True)
def setup_test_environment(request):
    """
    Spins up a Postgres container and sets the DATABASE_URL for tests.
    The container is reused across the test session.
    Handles both parallel (pytest-xdist) and sequential test runs.
    """
    # Check if we are running under xdist and get the worker id
    if hasattr(request.config, "workerinput"):
        worker_id = request.config.workerinput["workerid"]
    else:
        worker_id = "master"

    # A single container is shared across all test workers
    if worker_id == "master":
        # Start the container
        postgres_container = PostgresContainer("postgres:15")
        postgres_container.start()
        # Set the DATABASE_URL environment variable for Django settings
        os.environ["DATABASE_URL"] = postgres_container.get_connection_url()
        # Store the container object for teardown
        pytest.postgres_container = postgres_container
    # Workers wait until the master has set up the container
    else:
        # A small sleep to prevent a busy-wait loop from consuming too much CPU
        import time

        while not hasattr(pytest, "postgres_container"):
            time.sleep(0.1)

    # Yield to run the tests
    yield

    # Teardown logic
    if worker_id == "master":
        # Stop the container
        pytest.postgres_container.stop()
