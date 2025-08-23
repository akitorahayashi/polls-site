#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Wait for the database to be ready
# The host is 'db' as defined in docker-compose.yml
# The port is 5432, the default for PostgreSQL
echo "Waiting for database..."

# Check if the environment variable DB_HOST is set, otherwise default to "db"
DB_HOST=${DB_HOST:-db}

# Loop until the database is ready
# Use nc (netcat) to check if the port is open
while ! nc -z "$DB_HOST" 5432; do
  echo "Waiting for database connection at $DB_HOST:5432..."
  sleep 1
done

echo "Database is ready."

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate

# Execute the command passed to the script (e.g., gunicorn)
# This allows the script to be a generic entrypoint.
echo "Starting application..."
exec "$@"
