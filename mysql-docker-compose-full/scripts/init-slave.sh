#!/bin/bash
set -euo pipefail

echo "===========================================" 
echo "MySQL Slave Initialization Starting..."
echo "==========================================="

echo "[1/6] Waiting for local MySQL to start..."
RETRIES=30
for i in $(seq 1 $RETRIES); do
    if mysql -uroot -proot -e "SELECT 1;" &>/dev/null; then
        echo "✓ Local MySQL is ready!"
        break
    fi
    if [ $i -eq $RETRIES ]; then
        echo "✗ Failed to connect to local MySQL after $RETRIES attempts"
        exit 1
    fi
    echo "  Attempt $i/$RETRIES - waiting..."
    sleep 2
done

echo "[2/6] Waiting for Master to be available..."
RETRIES=30
for i in $(seq 1 $RETRIES); do
    if mysql -h mysql-master -P3306 -uroot -proot -e "SELECT 1;" &>/dev/null; then
        echo "✓ Master MySQL is ready!"
        break
    fi
    if [ $i -eq $RETRIES ]; then
        echo "✗ Failed to connect to Master MySQL after $RETRIES attempts"
        exit 1
    fi
    echo "  Attempt $i/$RETRIES - waiting for master..."
    sleep 2
done

echo "[3/6] Ensuring database exists..."
mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS ollehsports;"
echo "✓ Database ollehsports ready"

echo "[4/6] Stopping and resetting old replication..."
mysql -uroot -proot <<-EOSQL
  STOP SLAVE;
  RESET SLAVE ALL;
EOSQL
echo "✓ Old replication reset"

echo "[5/6] Configuring and starting replication..."
mysql -uroot -proot <<-EOSQL
  CHANGE MASTER TO
    MASTER_HOST='mysql-master',
    MASTER_PORT=3306,
    MASTER_USER='repl',
    MASTER_PASSWORD='replpassword',
    MASTER_AUTO_POSITION=1;
  START SLAVE;
EOSQL
echo "✓ Replication configured and started"

echo "[6/6] Checking replication status..."
mysql -uroot -proot -e "SHOW SLAVE STATUS\G" | grep -E "(Slave_IO_Running|Slave_SQL_Running|Last_Error)"

echo "==========================================="
echo "MySQL Slave Initialization Completed!"
echo "==========================================="
