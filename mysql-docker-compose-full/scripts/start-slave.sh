#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "MySQL Slave Container Starting..."
echo "=========================================="

# Combine default slave parameters with any passed arguments
args=(
  --default-authentication-plugin=mysql_native_password
  --character-set-server=utf8mb4
  --collation-server=utf8mb4_unicode_ci
  --server-id=2
  --read-only=1
  --gtid-mode=ON
  --enforce-gtid-consistency
  "$@"
)

echo "Starting MySQL with slave configuration..."
echo "Parameters: ${args[*]}"

# 1) Start mysqld in background with all parameters
docker-entrypoint.sh mysqld "${args[@]}" &
MYSQL_PID=$!

# 2) Wait for MySQL to be ready
echo "Waiting for MySQL daemon to start..."
RETRIES=30
for i in $(seq 1 $RETRIES); do
    if mysql -uroot -proot -e "SELECT 1;" &>/dev/null; then
        echo "✓ MySQL daemon is ready!"
        break
    fi
    if [ $i -eq $RETRIES ]; then
        echo "✗ MySQL daemon failed to start after $RETRIES attempts"
        exit 1
    fi
    sleep 2
done

# 3) Run slave initialization
echo "Running slave initialization script..."
/docker-entrypoint-initdb.d/init-slave.sh

echo "✓ Slave initialization completed successfully!"

# 4) Wait for main mysqld process to finish
wait "$MYSQL_PID"