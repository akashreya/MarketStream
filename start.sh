#!/bin/bash

echo "Starting MarketStream Platform..."

# Check if Docker is running
if ! docker ps >/dev/null 2>&1; then
    echo "Docker is not running. Please start Docker first."
    exit 1
fi

echo "Docker is running. Starting services..."

# Start infrastructure services first
echo "Starting infrastructure services (Kafka, Redis)..."
docker-compose up -d zookeeper kafka redis

# Wait for services to be healthy
echo "Waiting for services to be ready..."
sleep 30

# Start the main application
echo "Starting MarketStream application..."
docker-compose up -d marketstream kafka-ui

echo "All services started! Access points:"
echo "- MarketStream Frontend: http://localhost:8090"
echo "- Kafka UI: http://localhost:8091"
echo "- Health Check: http://localhost:8090/actuator/health"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop services: docker-compose down"