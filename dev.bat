@echo off
echo ============================================
echo MarketStream Development Mode
echo ============================================
echo.
echo This will start:
echo - Infrastructure services (Kafka, Redis) in Docker
echo - Backend via Gradle (with hot reload)
echo - Frontend dev server (with hot reload)
echo.
echo Starting infrastructure services...
docker-compose -f docker-compose.dev.yml up -d

echo.
echo Starting backend in new window...
start "MarketStream Backend" cmd /k "cd backend && gradlew.bat bootRun"

echo.
echo Starting frontend in new window...
start "MarketStream Frontend" cmd /k "cd frontend && npm start"

echo.
echo ============================================
echo Development servers starting...
echo ============================================
echo.
echo Access points:
echo - Frontend (dev server): http://localhost:1234 
echo - Backend API: http://localhost:8090
echo - Kafka UI: http://localhost:8091
echo.
echo Press any key to stop all services...
pause >nul

echo.
echo Stopping services...
docker-compose -f docker-compose.dev.yml down
echo Development mode stopped.