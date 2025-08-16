@echo off
echo Starting MarketStream Platform...

REM Check if Docker is running
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)

echo Docker is running. Starting services...

REM Start infrastructure services first
echo Starting infrastructure services (Kafka, Redis)...
docker-compose up -d zookeeper kafka redis

REM Wait for services to be healthy
echo Waiting for services to be ready...
timeout /t 30

REM Start the main application
echo Starting MarketStream application...
docker-compose up -d marketstream kafka-ui

echo All services started! Access points:
echo - MarketStream Frontend: http://localhost:8090
echo - Kafka UI: http://localhost:8091
echo - Health Check: http://localhost:8090/actuator/health
echo.
echo To view logs: docker-compose logs -f
echo To stop services: docker-compose down
echo.
pause