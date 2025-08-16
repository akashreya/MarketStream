#!/bin/bash

# Startup script for MarketStream All-in-One Container
# Optimized for AWS t2.micro (1 vCPU, 1GB RAM)

set -e

echo "========================================="
echo "MarketStream All-in-One Container"
echo "Starting services for AWS t2.micro..."
echo "========================================="

# Set memory limits for t2.micro
export JAVA_OPTS="-Xms128m -Xmx400m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseStringDeduplication -Djava.security.egd=file:/dev/./urandom"
export KAFKA_HEAP_OPTS="-Xmx128m -Xms64m -XX:+UseG1GC"

# Create log directories
mkdir -p /var/log/supervisor
mkdir -p /app/data/{kafka,zookeeper,redis}

# Ensure proper permissions
sudo chown -R appuser:appuser /app/data /var/log/supervisor

# Display memory info
echo "System Memory Information:"
free -h

echo "Starting services with Supervisor..."
echo "Services will start in this order:"
echo "1. Redis (priority 100)"
echo "2. Zookeeper (priority 200)" 
echo "3. Kafka (priority 300)"
echo "4. MarketStream App (priority 400)"
echo "5. Nginx (priority 500)"
echo ""

# Start supervisor (which will start all services)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf