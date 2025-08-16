#!/bin/bash
set -e

echo "==============================================="
echo "MarketStream Complete Build and Deploy Pipeline"
echo "==============================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${BLUE}[$1/8] $2${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Step 1: Check prerequisites
print_step 1 "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

if ! docker ps &> /dev/null; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed or not in PATH"
    exit 1
fi

# Check npm
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed or not in PATH"
    exit 1
fi

# Check Java
if ! command -v java &> /dev/null; then
    print_error "Java is not installed or not in PATH"
    exit 1
fi

print_success "Docker is running"
print_success "Node.js is available"
print_success "Java is available"
echo

# Step 2: Clean previous builds
print_step 2 "Cleaning previous builds..."
rm -rf frontend/build
rm -rf frontend/dist
rm -rf backend/build
rm -rf backend/src/main/resources/static
print_success "Cleaned previous builds"
echo

# Step 3: Install frontend dependencies
print_step 3 "Installing frontend dependencies..."
cd frontend
npm install
if [ $? -ne 0 ]; then
    print_error "Failed to install frontend dependencies"
    exit 1
fi
cd ..
print_success "Frontend dependencies installed"
echo

# Step 4: Build frontend
print_step 4 "Building frontend..."
cd frontend
npm run build
if [ $? -ne 0 ]; then
    print_error "Failed to build frontend"
    exit 1
fi
cd ..
print_success "Frontend built successfully"
echo

# Step 5: Copy frontend to backend
print_step 5 "Integrating frontend into backend..."
mkdir -p backend/src/main/resources/static
cp -r frontend/build/* backend/src/main/resources/static/
if [ $? -ne 0 ]; then
    print_error "Failed to copy frontend to backend"
    exit 1
fi
print_success "Frontend integrated into backend"
echo

# Step 6: Build backend
print_step 6 "Building backend..."
cd backend
chmod +x gradlew
./gradlew clean build -x test
if [ $? -ne 0 ]; then
    print_error "Failed to build backend"
    exit 1
fi
cd ..
print_success "Backend built successfully"
echo

# Step 7: Build Docker image
print_step 7 "Building Docker image..."
docker-compose build --no-cache marketstream
if [ $? -ne 0 ]; then
    print_error "Failed to build Docker image"
    exit 1
fi
print_success "Docker image built successfully"
echo

# Step 8: Start complete infrastructure
print_step 8 "Starting MarketStream infrastructure..."
echo "Starting infrastructure services..."
docker-compose up -d zookeeper kafka redis

echo "Waiting for infrastructure to be ready..."
sleep 30

echo "Starting MarketStream application..."
docker-compose up -d marketstream kafka-ui

echo
echo "==============================================="
echo -e "${GREEN}✓ MarketStream deployment completed successfully!${NC}"
echo "==============================================="
echo
echo "Access points:"
echo "- MarketStream Application: http://localhost:8090"
echo "- Kafka UI: http://localhost:8091"
echo "- Health Check: http://localhost:8090/actuator/health"
echo
echo "Useful commands:"
echo "- View logs: docker-compose logs -f marketstream"
echo "- Stop services: docker-compose down"
echo "- Restart app: docker-compose restart marketstream"
echo
echo "Press Enter to view logs or Ctrl+C to exit..."
read
docker-compose logs -f marketstream