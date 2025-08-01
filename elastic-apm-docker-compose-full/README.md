
# Elastic APM Docker Compose - Complete Stack

This configuration provides a complete Elastic APM (Application Performance Monitoring) stack for monitoring application performance, tracking errors, and analyzing distributed traces.

## Architecture Overview

```
Applications -> APM Server -> Elasticsearch -> Kibana APM UI
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Elasticsearch** | 9200, 9300 | Data storage and search engine |
| **Kibana** | 5601 | APM UI and visualization dashboard |
| **APM Server** | 8200 | APM data collection and processing |

## Quick Start

### 1. Start the Stack

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

### 2. Verify Services

- **APM Server**: http://localhost:8200
- **Kibana APM**: http://localhost:5601/app/apm
- **Elasticsearch**: http://localhost:9200/_cluster/health

### 3. Test APM Integration

#### Option A: Node.js Test Script (Included)

```bash
# Install dependencies
npm install

# Run test application
npm test
```

#### Option B: Configure Your Application

**Node.js Example:**
```javascript
const apm = require('elastic-apm-node').start({
  serviceName: 'my-app',
  serverUrl: 'http://localhost:8200',
  environment: 'development'
});
```

**Java Example:**
```java
// Add to JVM arguments
-javaagent:elastic-apm-agent.jar
-Delastic.apm.service_name=my-app
-Delastic.apm.server_urls=http://localhost:8200
-Delastic.apm.environment=development
```

**Python Example:**
```python
import elasticapm
from elasticapm.contrib.django.middleware import TracingMiddleware

apm = elasticapm.Client({
    'SERVICE_NAME': 'my-app',
    'SERVER_URL': 'http://localhost:8200',
    'ENVIRONMENT': 'development',
})
```

## APM Server Configuration

### Authentication
- **Anonymous access**: Enabled for development
- **Rate limiting**: 1000 requests/IP, 10000 events/IP
- **Allowed agents**: All APM agents supported

### Data Collection
- **Max event size**: 300KB
- **Personal data capture**: Disabled
- **RUM support**: Enabled with CORS
- **Source mapping**: Enabled for JavaScript

### Performance Settings
- **Concurrent requests**: 40
- **Read timeout**: 30s
- **Write timeout**: 30s
- **Idle timeout**: 45s

## Kibana APM Features

### 1. Service Map
View your application architecture and dependencies:
- Navigate to **APM** → **Service Map**
- Visualize service connections and performance

### 2. Services Overview
Monitor individual services:
- **APM** → **Services**
- View throughput, response times, and error rates

### 3. Traces
Analyze distributed traces:
- **APM** → **Traces**
- Drill down into individual requests

### 4. Errors
Track and analyze errors:
- **APM** → **Errors**
- View error trends and stack traces

### 5. Metrics
Monitor infrastructure metrics:
- **APM** → **Metrics**
- System and JVM metrics (when available)

## Supported APM Agents

| Language | Agent | Configuration |
|----------|-------|---------------|
| **Node.js** | elastic-apm-node | `npm install elastic-apm-node` |
| **Java** | elastic-apm-agent | Download JAR, add JVM args |
| **Python** | elastic-apm | `pip install elastic-apm` |
| **Ruby** | elastic-apm | `gem install elastic-apm` |
| **Go** | apm-agent-go | `go get go.elastic.co/apm` |
| **PHP** | elastic-apm-php | PECL extension |
| **C#/.NET** | Elastic.Apm | NuGet package |
| **JavaScript/RUM** | @elastic/apm-rum | Browser agent |

## Index Management

APM data is stored in date-based indices:
- **apm-*** pattern for all APM data
- **Rollover policy**: 30 days (configurable)
- **Compression**: Best compression enabled
- **Replicas**: 0 (development setup)

## Health Monitoring

All services include comprehensive health checks:

```bash
# Check APM Server health
curl http://localhost:8200/

# Check Elasticsearch cluster
curl http://localhost:9200/_cluster/health

# Check Kibana status
curl http://localhost:5601/api/status

# Service health via Docker
docker-compose exec apm-server curl -f http://localhost:8200/
```

## Performance Tuning

### Elasticsearch Optimization
- **Heap size**: 1GB (adjust based on data volume)
- **Index buffer**: 256MB
- **Memory lock**: Enabled
- **Compression**: Best compression for storage efficiency

### APM Server Optimization
- **Concurrent requests**: 40 (adjust based on load)
- **Event batching**: Optimized for throughput
- **Memory management**: Automatic garbage collection

## Troubleshooting

### Common Issues

**APM Server not receiving data:**
```bash
# Check connectivity
curl -I http://localhost:8200/

# Verify agent configuration
# Ensure serverUrl points to http://localhost:8200

# Check logs
docker-compose logs apm-server
```

**Data not appearing in Kibana:**
```bash
# Check Elasticsearch indices
curl http://localhost:9200/_cat/indices/apm-*

# Verify APM server is processing events
curl http://localhost:8200/intake/v2/events
```

**High memory usage:**
```bash
# Adjust Elasticsearch heap size in docker-compose.yml
ES_JAVA_OPTS=-Xms512m -Xmx512m

# Monitor memory usage
docker stats
```

**Dashboard setup issues:**
```bash
# Restart services to reload dashboards
docker-compose restart kibana apm-server

# Manually setup dashboards
docker-compose exec apm-server apm-server setup --dashboards
```

### Performance Monitoring

```bash
# APM Server stats
curl http://localhost:8200/stats

# Elasticsearch cluster stats
curl http://localhost:9200/_cluster/stats

# Index statistics
curl http://localhost:9200/apm-*/_stats
```

## Production Considerations

**⚠️ This configuration is for development. For production:**

1. **Enable security** (`xpack.security.enabled=true`)
2. **Configure authentication** (API keys or tokens)
3. **Use multiple Elasticsearch nodes**
4. **Implement proper SSL/TLS**
5. **Configure retention policies**
6. **Set up monitoring and alerting**
7. **Use external load balancers**
8. **Implement backup strategies**

## Sample Applications

The included test script (`test-apm.js`) demonstrates:
- Transaction tracking
- Error capture
- Custom metrics
- Span creation
- Context and labels

Run with: `npm test`

## File Structure

```
elastic-apm-docker-compose-full/
├── docker-compose.yml          # Main configuration
├── apm-server.yml             # APM Server configuration
├── README.md                  # This file
├── package.json               # Node.js test dependencies
├── test-apm.js               # APM test script
└── examples/                  # Language-specific examples
```

## Version Information

- **Elasticsearch**: 8.13.4
- **Kibana**: 8.13.4
- **APM Server**: 8.13.4
- **Docker Compose**: 3.7+

## Useful Commands

```bash
# Quick health check all services
docker-compose exec elasticsearch curl -f http://localhost:9200/_cluster/health
docker-compose exec kibana curl -f http://localhost:5601/api/status  
docker-compose exec apm-server curl -f http://localhost:8200/

# View APM indices
curl "http://localhost:9200/_cat/indices/apm-*?v"

# Search APM data
curl "http://localhost:9200/apm-*/_search?q=service.name:my-app&size=5&pretty"

# Monitor APM server performance
curl "http://localhost:8200/stats?pretty"
```

## License

This configuration is provided as-is for educational and development purposes.

