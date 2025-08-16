#!/bin/bash

echo "============================================"
echo "MarketStream Development Mode"
echo "============================================"
echo
echo "This will start:"
echo "- Infrastructure services (Kafka, Redis) in Docker"
echo "- Backend via Gradle (with hot reload)"
echo "- Frontend dev server (with hot reload)"
echo

echo "Starting infrastructure services..."
docker-compose -f docker-compose.dev.yml up -d

echo
echo "Starting backend..."
cd backend
./gradlew bootRun &
BACKEND_PID=$!
cd ..

echo
echo "Starting frontend..."
cd frontend
npm start &
FRONTEND_PID=$!
cd ..

echo
echo "============================================"
echo "Development servers started!"
echo "============================================"
echo
echo "Access points:"
echo "- Frontend (dev server): http://localhost:1234"
echo "- Backend API: http://localhost:8090"
echo "- Kafka UI: http://localhost:8091"
echo
echo "Press Ctrl+C to stop all services..."

# Function to cleanup on exit
cleanup() {
    echo
    echo "Stopping services..."
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    docker-compose -f docker-compose.dev.yml down
    echo "Development mode stopped."
    exit 0
}

# Trap Ctrl+C
trap cleanup SIGINT

# Wait for interrupt
while true; do
    sleep 1
done