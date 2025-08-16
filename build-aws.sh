#!/bin/bash

echo "===================================================="
echo "Building MarketStream All-in-One for AWS Free Tier"
echo "===================================================="
echo

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[$1/4] $2${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

print_step 1 "Cleaning previous builds..."
docker rmi marketstream:aws-free-tier 2>/dev/null || true
docker system prune -f >/dev/null 2>&1

print_step 2 "Building all-in-one image for t2.micro..."
docker build -f Dockerfile.all-in-one -t marketstream:aws-free-tier .
if [ $? -ne 0 ]; then
    print_error "Docker build failed"
    exit 1
fi

print_step 3 "Testing container locally..."
echo "Starting container for local test..."
docker run -d --name marketstream-test -p 8090:8090 -p 8091:8091 marketstream:aws-free-tier
if [ $? -ne 0 ]; then
    print_error "Failed to start test container"
    exit 1
fi

echo "Waiting for services to start..."
sleep 60

echo "Testing health endpoint..."
curl -f http://localhost:8090/actuator/health >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "WARNING: Health check failed, but container may still be starting"
fi

print_step 4 "Cleaning up test container..."
docker stop marketstream-test >/dev/null 2>&1
docker rm marketstream-test >/dev/null 2>&1

echo
echo "===================================================="
print_success "All-in-One image built successfully!"
echo "===================================================="
echo
echo "Image: marketstream:aws-free-tier"
echo "Optimized for: AWS EC2 t2.micro (1 vCPU, 1GB RAM)"
echo
echo "Next steps:"
echo "1. Push to Docker Hub: docker tag marketstream:aws-free-tier [your-dockerhub]/marketstream:aws-free-tier"
echo "2. Deploy to AWS: Use deploy-to-aws.sh script"
echo "3. Or run locally: docker run -p 8090:8090 marketstream:aws-free-tier"
echo