#!/bin/bash
set -e

echo "=========================================="
echo "MongoDB Replica Set Initialization"
echo "=========================================="
echo "Starting initialization process..."

# Function to check if MongoDB is ready
check_mongo_ready() {
    local host=$1
    local max_retries=30
    local retry=0
    
    echo "[INFO] Checking if $host is ready..."
    while [ $retry -lt $max_retries ]; do
        if mongosh --host $host --username root --password rootpassword --authenticationDatabase admin --eval "db.runCommand('ping')" --quiet &>/dev/null; then
            echo "✓ $host is ready!"
            return 0
        fi
        retry=$((retry + 1))
        echo "  [$retry/$max_retries] Waiting for $host..."
        sleep 2
    done
    
    echo "✗ $host is not ready after $max_retries attempts"
    return 1
}

# Check all MongoDB instances
echo ""
echo "[1/4] Waiting for all MongoDB instances to be ready..."
check_mongo_ready "mongo-primary:27017" || exit 1
check_mongo_ready "mongo-secondary1:27017" || exit 1  
check_mongo_ready "mongo-secondary2:27017" || exit 1

echo ""
echo "[2/4] Checking replica set status..."

# Check if replica set is already initialized
RS_STATUS=$(mongosh --host mongo-primary:27017 --username root --password rootpassword --authenticationDatabase admin --eval "try { rs.status().ok } catch (e) { 0 }" --quiet 2>/dev/null || echo "0")

if [ "$RS_STATUS" = "1" ]; then
    echo "✓ Replica set is already initialized"
    echo ""
    echo "[INFO] Current replica set status:"
    mongosh --host mongo-primary:27017 --username root --password rootpassword --authenticationDatabase admin --eval "rs.status()" --quiet
    echo ""
    echo "=========================================="
    echo "Replica set initialization completed!"
    echo "=========================================="
    exit 0
fi

echo ""
echo "[3/4] Initializing replica set..."

# Initialize replica set
mongosh --host mongo-primary:27017 --username root --password rootpassword --authenticationDatabase admin --eval "
rs.initiate({
  _id: 'rs0',
  members: [
    { _id: 0, host: 'mongo-primary:27017', priority: 2 },
    { _id: 1, host: 'mongo-secondary1:27017', priority: 1 },
    { _id: 2, host: 'mongo-secondary2:27017', priority: 1 }
  ]
})
" --quiet

echo "✓ Replica set initiation command sent"

echo ""
echo "[4/4] Waiting for replica set to stabilize..."

# Wait for replica set to be fully ready
RETRIES=30
for i in $(seq 1 $RETRIES); do
    echo "  [$i/$RETRIES] Checking replica set health..."
    
    # Check if we have a primary and secondaries
    PRIMARY_COUNT=$(mongosh --host mongo-primary:27017 --username root --password rootpassword --authenticationDatabase admin --eval "rs.status().members.filter(m => m.stateStr === 'PRIMARY').length" --quiet 2>/dev/null || echo "0")
    SECONDARY_COUNT=$(mongosh --host mongo-primary:27017 --username root --password rootpassword --authenticationDatabase admin --eval "rs.status().members.filter(m => m.stateStr === 'SECONDARY').length" --quiet 2>/dev/null || echo "0")
    
    if [ "$PRIMARY_COUNT" = "1" ] && [ "$SECONDARY_COUNT" = "2" ]; then
        echo "✓ Replica set is healthy: 1 PRIMARY + 2 SECONDARY"
        break
    fi
    
    sleep 3
done

echo ""
echo "=========================================="
echo "Final replica set status:"
echo "=========================================="
mongosh --host mongo-primary:27017 --username root --password rootpassword --authenticationDatabase admin --eval "rs.status()" --quiet

echo ""
echo "=========================================="
echo "MongoDB Replica Set initialization completed!"
echo "=========================================="
