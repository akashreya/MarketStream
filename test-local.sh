#!/bin/bash

# Local testing script for AWS Free Tier container
# Tests memory usage and basic functionality

echo "============================================="
echo "MarketStream AWS Container Local Test"
echo "============================================="
echo

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Cleanup any existing container
print_step "Cleaning up existing test containers..."
docker stop marketstream-test >/dev/null 2>&1 || true
docker rm marketstream-test >/dev/null 2>&1 || true

# Start container with memory limit (simulating t2.micro)
print_step "Starting container with 1GB memory limit..."
docker run -d --name marketstream-test \
    --memory=1g \
    --cpus=1 \
    -p 8090:8090 \
    -p 8091:8091 \
    marketstream:aws-free-tier

if [ $? -ne 0 ]; then
    print_error "Failed to start container"
    exit 1
fi

print_success "Container started"

# Wait for services to initialize
print_step "Waiting for services to start (this may take 2-3 minutes)..."
echo "Service startup order: Redis → Zookeeper → Kafka → MarketStream → Nginx"

# Monitor memory usage during startup
for i in {1..180}; do
    sleep 1
    
    # Check if container is still running
    if ! docker ps | grep marketstream-test >/dev/null; then
        print_error "Container stopped unexpectedly"
        echo "Checking logs..."
        docker logs marketstream-test
        exit 1
    fi
    
    # Show memory usage every 30 seconds
    if [ $((i % 30)) -eq 0 ]; then
        echo "[$i/180s] Memory usage:"
        docker stats marketstream-test --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    fi
    
    # Test health endpoint
    if [ $i -gt 120 ]; then
        if curl -s -f http://localhost:8090/actuator/health >/dev/null 2>&1; then
            print_success "Application is responding!"
            break
        fi
    fi
    
    printf "."
done

echo

# Final health check
print_step "Running comprehensive health checks..."

# Check health endpoint
if curl -s -f http://localhost:8090/actuator/health >/dev/null 2>&1; then
    print_success "Health endpoint responding"
else
    print_error "Health endpoint not responding"
fi

# Check if main page loads
if curl -s -f http://localhost:8090/ >/dev/null 2>&1; then
    print_success "Main application page loading"
else
    print_warning "Main page may still be loading"
fi

# Check WebSocket endpoint
if curl -s -f http://localhost:8090/ws/info >/dev/null 2>&1; then
    print_success "WebSocket endpoint available"
else
    print_warning "WebSocket endpoint check inconclusive"
fi

# Memory and CPU usage
print_step "Final resource usage:"
docker stats marketstream-test --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Service status inside container
print_step "Service status inside container:"
docker exec marketstream-test supervisorctl status 2>/dev/null || echo "Unable to check service status"

# Show logs
print_step "Recent application logs:"
docker logs --tail 10 marketstream-test

echo
echo "============================================="
print_success "Test completed!"
echo "============================================="
echo
echo "Container is running at:"
echo "- Application: http://localhost:8090"
echo "- Kafka UI: http://localhost:8091 (if enabled)"
echo
echo "To interact with the container:"
echo "docker exec -it marketstream-test bash"
echo
echo "To stop the test:"
echo "docker stop marketstream-test && docker rm marketstream-test"
echo
echo "If all tests pass, the container is ready for AWS deployment!"
echo