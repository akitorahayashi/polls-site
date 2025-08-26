# This file is intentionally left blank.
#
# Previously, this file contained a pytest fixture that used 'testcontainers'
# to manage a temporary PostgreSQL database for the test suite.
#
# The testing strategy has been refactored to use a dedicated, long-running
# test database service managed by Docker Compose. The configuration for this
# database is now handled by the '.env.test' file and the 'make test' command.
#
# Django's settings now automatically pick up the DATABASE_URL from the
# environment, so no special test setup fixtures are needed in this file.
