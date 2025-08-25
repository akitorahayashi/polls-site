import os
from pathlib import Path

import pytest
from filelock import FileLock, Timeout
from testcontainers.postgres import PostgresContainer

# Define paths for temporary files used for coordination
# These files are created in the project root, which is the current working directory during tests.
# Using Path for robust path manipulation.
LOCK_FILE = Path(".container.lock")
DB_URL_FILE = Path(".db_url")
# Timeout for acquiring the file lock, in seconds
LOCK_TIMEOUT = 60


@pytest.fixture(scope="session", autouse=True)
def setup_test_environment(request):
    """
    Manages a single PostgreSQL container for the entire test session,
    ensuring robust setup and teardown in parallel (pytest-xdist) and sequential test runs.

    This fixture uses a file lock to ensure that only one test worker process
    (the "primary" worker) is responsible for starting and stopping the container.
    Other workers wait for the primary worker to complete the setup.

    1.  **Locking**: Each worker attempts to acquire a file lock. The first one wins and
        becomes the primary.
    2.  **Primary Worker**:
        - Starts the PostgreSQL container.
        - Writes the container's database URL to a temporary file (`.db_url`).
        - Sets the DATABASE_URL environment variable for its own process.
        - Registers a finalizer function to stop the container and clean up
          temporary files after all tests complete.
        - Releases the lock.
    3.  **Other Workers**:
        - Wait until they can acquire the lock (which happens after the primary releases it).
        - Read the database URL from the `.db_url` file.
        - Set the DATABASE_URL environment variable for their own process.
        - Release the lock and proceed with tests.

    This approach is process-safe and avoids the race conditions and state-sharing
    issues inherent in the previous implementation.
    """
    try:
        # Attempt to acquire the lock. If it fails, another process holds it.
        lock = FileLock(LOCK_FILE)
        lock.acquire(timeout=LOCK_TIMEOUT)

        # If the DB URL file doesn't exist, this process is the primary worker.
        if not DB_URL_FILE.exists():
            # This is the primary worker, responsible for setup.
            postgres_container = PostgresContainer("postgres:15")
            postgres_container.start()

            # Define a finalizer to be called when the session ends.
            # This ensures cleanup happens only once and by the primary worker.
            def finalizer():
                postgres_container.stop()
                # Clean up the temporary files
                DB_URL_FILE.unlink(missing_ok=True)
                LOCK_FILE.unlink(missing_ok=True)

            request.addfinalizer(finalizer)

            # Write the connection URL to the file for other workers to use.
            db_url = postgres_container.get_connection_url()
            DB_URL_FILE.write_text(db_url)
            os.environ["DATABASE_URL"] = db_url
        else:
            # This is a secondary worker. The container is already running.
            # Read the connection URL from the file created by the primary worker.
            db_url = DB_URL_FILE.read_text()
            os.environ["DATABASE_URL"] = db_url

        # Release the lock so other workers can proceed.
        lock.release()

    except Timeout:
        # If the lock could not be acquired within the timeout, fail the test.
        pytest.fail(
            f"Could not acquire lock on {LOCK_FILE} within {LOCK_TIMEOUT} seconds. "
            "Another process may be holding it, or the setup is taking too long."
        )

    # Yield to let the tests run.
    yield
