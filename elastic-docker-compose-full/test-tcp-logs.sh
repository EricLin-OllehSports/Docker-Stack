#!/bin/bash
# Test script for TCP log sending to Logstash

echo "Testing TCP log sending to Logstash port 5001..."

# Test JSON log messages
echo '{"timestamp":"2024-08-01T10:05:00","level":"INFO","service":"test-app","message":"TCP test message 1"}' | nc localhost 5001
sleep 1

echo '{"timestamp":"2024-08-01T10:05:01","level":"ERROR","service":"test-app","message":"TCP test error message","error_code":500}' | nc localhost 5001
sleep 1

echo '{"timestamp":"2024-08-01T10:05:02","level":"WARN","service":"test-app","message":"TCP test warning message"}' | nc localhost 5001

echo "Test messages sent to Logstash via TCP port 5001"
echo "Check Elasticsearch indices at: http://localhost:9200/_cat/indices"
echo "View logs in Kibana at: http://localhost:5601"