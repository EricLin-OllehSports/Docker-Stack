#!/bin/bash
set -e

echo "=========================================="
echo "MongoDB Sharded Cluster Initialization"
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

# Check all components
echo ""
echo "[1/6] Waiting for all components to be ready..."
echo "Checking Config Servers..."
check_mongo_ready "mongo-config1:27017" || exit 1
check_mongo_ready "mongo-config2:27017" || exit 1
check_mongo_ready "mongo-config3:27017" || exit 1

echo "Checking Shard Servers..."
check_mongo_ready "mongo-shard1-1:27017" || exit 1
check_mongo_ready "mongo-shard1-2:27017" || exit 1
check_mongo_ready "mongo-shard1-3:27017" || exit 1
check_mongo_ready "mongo-shard2-1:27017" || exit 1
check_mongo_ready "mongo-shard2-2:27017" || exit 1
check_mongo_ready "mongo-shard2-3:27017" || exit 1

echo "Checking Mongos Router..."
check_mongo_ready "mongo-router:27017" || exit 1

echo ""
echo "[2/6] Initializing Config Server replica set..."

# Check if config replica set is already initialized
CONFIG_RS_STATUS=$(mongosh --host mongo-config1:27017 --username root --password rootpassword --authenticationDatabase admin --eval "try { rs.status().ok } catch (e) { 0 }" --quiet 2>/dev/null || echo "0")

if [ "$CONFIG_RS_STATUS" = "1" ]; then
    echo "✓ Config Server replica set is already initialized"
else
    echo "Initializing Config Server replica set..."
    mongosh --host mongo-config1:27017 --username root --password rootpassword --authenticationDatabase admin --eval "
    rs.initiate({
      _id: 'configrs',
      configsvr: true,
      members: [
        { _id: 0, host: 'mongo-config1:27017', priority: 2 },
        { _id: 1, host: 'mongo-config2:27017', priority: 1 },
        { _id: 2, host: 'mongo-config3:27017', priority: 1 }
      ]
    })
    " --quiet
    echo "✓ Config Server replica set initiated"
    
    # Wait for config replica set to be ready
    echo "Waiting for Config Server replica set to stabilize..."
    sleep 15
fi

echo ""
echo "[3/6] Initializing Shard 1 replica set..."

# Check if shard1 replica set is already initialized
SHARD1_RS_STATUS=$(mongosh --host mongo-shard1-1:27017 --username root --password rootpassword --authenticationDatabase admin --eval "try { rs.status().ok } catch (e) { 0 }" --quiet 2>/dev/null || echo "0")

if [ "$SHARD1_RS_STATUS" = "1" ]; then
    echo "✓ Shard 1 replica set is already initialized"
else
    echo "Initializing Shard 1 replica set..."
    mongosh --host mongo-shard1-1:27017 --username root --password rootpassword --authenticationDatabase admin --eval "
    rs.initiate({
      _id: 'shard1rs',
      members: [
        { _id: 0, host: 'mongo-shard1-1:27017', priority: 2 },
        { _id: 1, host: 'mongo-shard1-2:27017', priority: 1 },
        { _id: 2, host: 'mongo-shard1-3:27017', priority: 1 }
      ]
    })
    " --quiet
    echo "✓ Shard 1 replica set initiated"
    
    # Wait for shard1 replica set to be ready
    echo "Waiting for Shard 1 replica set to stabilize..."
    sleep 15
fi

echo ""
echo "[4/6] Initializing Shard 2 replica set..."

# Check if shard2 replica set is already initialized
SHARD2_RS_STATUS=$(mongosh --host mongo-shard2-1:27017 --username root --password rootpassword --authenticationDatabase admin --eval "try { rs.status().ok } catch (e) { 0 }" --quiet 2>/dev/null || echo "0")

if [ "$SHARD2_RS_STATUS" = "1" ]; then
    echo "✓ Shard 2 replica set is already initialized"
else
    echo "Initializing Shard 2 replica set..."
    mongosh --host mongo-shard2-1:27017 --username root --password rootpassword --authenticationDatabase admin --eval "
    rs.initiate({
      _id: 'shard2rs',
      members: [
        { _id: 0, host: 'mongo-shard2-1:27017', priority: 2 },
        { _id: 1, host: 'mongo-shard2-2:27017', priority: 1 },
        { _id: 2, host: 'mongo-shard2-3:27017', priority: 1 }
      ]
    })
    " --quiet
    echo "✓ Shard 2 replica set initiated"
    
    # Wait for shard2 replica set to be ready
    echo "Waiting for Shard 2 replica set to stabilize..."
    sleep 15
fi

echo ""
echo "[5/6] Adding shards to the cluster..."

# Check if shards are already added
SHARD_COUNT=$(mongosh --host mongo-router:27017 --username root --password rootpassword --authenticationDatabase admin --eval "sh.status().shards.length" --quiet 2>/dev/null || echo "0")

if [ "$SHARD_COUNT" = "2" ]; then
    echo "✓ All shards are already added to the cluster"
else
    echo "Adding Shard 1 to cluster..."
    mongosh --host mongo-router:27017 --username root --password rootpassword --authenticationDatabase admin --eval "
    sh.addShard('shard1rs/mongo-shard1-1:27017,mongo-shard1-2:27017,mongo-shard1-3:27017')
    " --quiet
    echo "✓ Shard 1 added"
    
    echo "Adding Shard 2 to cluster..."
    mongosh --host mongo-router:27017 --username root --password rootpassword --authenticationDatabase admin --eval "
    sh.addShard('shard2rs/mongo-shard2-1:27017,mongo-shard2-2:27017,mongo-shard2-3:27017')
    " --quiet
    echo "✓ Shard 2 added"
fi

echo ""
echo "[6/6] Enabling sharding on test database..."

# Enable sharding on a test database and collection
mongosh --host mongo-router:27017 --username root --password rootpassword --authenticationDatabase admin --eval "
sh.enableSharding('testdb');
sh.shardCollection('testdb.users', { '_id': 'hashed' });
" --quiet

echo "✓ Sharding enabled on testdb.users collection"

echo ""
echo "=========================================="
echo "Final cluster status:"
echo "=========================================="
mongosh --host mongo-router:27017 --username root --password rootpassword --authenticationDatabase admin --eval "sh.status()" --quiet

echo ""
echo "=========================================="
echo "MongoDB Sharded Cluster initialization completed!"
echo "=========================================="