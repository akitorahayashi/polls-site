#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e
# Exit immediately if a variable is unset.
set -u

# Wait for the database to be ready
echo "Waiting for database..."

# Use a Python script to wait for the database, removing dependency on netcat
python -c '
import socket
import time
import os
import sys

host = os.environ.get("DB_HOST", "db")
port = int(os.environ.get("DB_PORT", 5432))
timeout = int(os.environ.get("WAIT_TIMEOUT", 60))

start_time = time.monotonic()
while True:
    try:
        with socket.create_connection((host, port), timeout=1):
            break
    except (socket.timeout, ConnectionRefusedError, OSError):
        if time.monotonic() - start_time >= timeout:
            print(f"Error: Timed out waiting for database connection at {host}:{port}", file=sys.stderr)
            sys.exit(1)
        print(f"Waiting for database connection at {host}:{port}...")
        time.sleep(1)
'

echo "Database is ready."

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate

# Execute the command passed to the script (e.g., gunicorn)
echo "Starting application..."
exec "$@"
