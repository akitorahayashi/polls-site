#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e
# Exit immediately if a variable is unset.
set -u

# Wait for the database to be ready
echo "Waiting for database..."

# Get database connection details from environment variables with defaults
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-5432}
WAIT_TIMEOUT=60
SECONDS_WAITED=0

# Loop until the database is ready or timeout is reached
while ! nc -z -w 1 "$DB_HOST" "$DB_PORT"; do
  if [ "$SECONDS_WAITED" -ge "$WAIT_TIMEOUT" ]; then
    echo "Error: Timed out waiting for database connection at $DB_HOST:$DB_PORT"
    exit 1
  fi
  echo "Waiting for database connection at $DB_HOST:$DB_PORT... ($SECONDS_WAITED/$WAIT_TIMEOUT)"
  sleep 1
  SECONDS_WAITED=$((SECONDS_WAITED + 1))
done

echo "Database is ready."

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate

# Execute the command passed to the script (e.g., gunicorn)
echo "Starting application..."
exec "$@"
