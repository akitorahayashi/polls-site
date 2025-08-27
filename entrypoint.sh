#!/bin/sh

# Exit immediately if a command exits with a non-zero status ('e')
# or if an unset variable is used ('u').
set -eu

# Wait for the database to be ready
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-5432}
WAIT_TIMEOUT=${WAIT_TIMEOUT:-60}

echo "Waiting for database connection at ${DB_HOST}:${DB_PORT}..."

count=0
while ! nc -z "${DB_HOST}" "${DB_PORT}"; do
    count=$((count + 1))
    if [ ${count} -ge ${WAIT_TIMEOUT} ]; then
        echo "Error: Timed out waiting for database connection at ${DB_HOST}:${DB_PORT}" >&2
        exit 1
    fi
    echo "Waiting for database connection... (${count}/${WAIT_TIMEOUT}s)"
    sleep 1
done

echo "Database is ready."

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate

# Execute the command passed to the script (e.g., gunicorn)
echo "Starting application..."
exec "$@"
