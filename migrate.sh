#!/usr/bin/env bash
set -euo pipefail

# migrate.sh
# Runs numbered SQL scripts (e.g., 01-*.sql, 02-*.sql) against a Postgres container started by Docker Compose.
#
# Defaults:
#   - Compose service: postgres
#   - Database: misc
#   - User: admin
#   - SQL directory: ./initdb
#
# Usage:
#   ./migrate.sh
#   POSTGRES_DB=misc POSTGRES_USER=admin ./migrate.sh
#   POSTGRES_SERVICE=postgres SQL_DIR=./initdb ./migrate.sh
#
# Notes:
# - This script assumes your SQL files are idempotent (IF NOT EXISTS, ON CONFLICT, etc.).
# - It uses `docker compose exec` (service name), not container_name.

POSTGRES_SERVICE="${POSTGRES_SERVICE:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-misc}"
POSTGRES_USER="${POSTGRES_USER:-admin}"
SQL_DIR="${SQL_DIR:-./initdb}"

WAIT_SECONDS="${WAIT_SECONDS:-60}"
SLEEP_INTERVAL="${SLEEP_INTERVAL:-1}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found in PATH" >&2
  exit 127
fi

if [[ ! -d "$SQL_DIR" ]]; then
  echo "SQL_DIR not found: $SQL_DIR" >&2
  exit 2
fi

# Find SQL scripts (top-level only), sort by version-like order.
mapfile -t SQL_FILES < <(find "$SQL_DIR" -maxdepth 1 -type f -name '*.sql' | sort -V)

if [[ ${#SQL_FILES[@]} -eq 0 ]]; then
  echo "No .sql files found in: $SQL_DIR" >&2
  exit 3
fi

echo "Target:"
echo "  Service : $POSTGRES_SERVICE"
echo "  DB      : $POSTGRES_DB"
echo "  User    : $POSTGRES_USER"
echo "  SQL_DIR : $SQL_DIR"
echo

# Wait for Postgres readiness
echo "Waiting for Postgres to become ready (timeout: ${WAIT_SECONDS}s)..."
deadline=$((SECONDS + WAIT_SECONDS))
while true; do
  if docker compose exec -T "$POSTGRES_SERVICE" pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
    echo "Postgres is ready."
    break
  fi
  if (( SECONDS >= deadline )); then
    echo "Timed out waiting for Postgres readiness." >&2
    exit 4
  fi
  sleep "$SLEEP_INTERVAL"
done
echo

# Run scripts in order
for f in "${SQL_FILES[@]}"; do
  base="$(basename "$f")"
  echo "==> Applying: $base"

  # Feed SQL file content into psql running inside the container.
  # -v ON_ERROR_STOP=1 makes psql exit non-zero on the first error.
  cat "$f" | docker compose exec -T "$POSTGRES_SERVICE" \
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1

  echo "==> Done: $base"
  echo
done

echo "All migrations applied successfully."
