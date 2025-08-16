@echo off
setlocal enabledelayedexpansion

echo ===============================================
echo MarketStream Complete Build and Deploy Pipeline
echo ===============================================
echo.

REM Check prerequisites
echo [1/8] Checking prerequisites...

REM Check Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not installed or not in PATH
    pause
    exit /b 1
)

docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)

REM Check Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js is not installed or not in PATH
    pause
    exit /b 1
)

REM Check Java
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Java is not installed or not in PATH
    pause
    exit /b 1
)

echo ✓ Docker is running
echo ✓ Node.js is available
echo ✓ Java is available
echo.

REM Step 2: Clean previous builds
echo [2/8] Cleaning previous builds...
if exist "frontend\build" rmdir /s /q "frontend\build"
if exist "frontend\dist" rmdir /s /q "frontend\dist"
if exist "backend\build" rmdir /s /q "backend\build"
if exist "backend\src\main\resources\static" rmdir /s /q "backend\src\main\resources\static"
echo ✓ Cleaned previous builds
echo.

REM Step 3: Install frontend dependencies
echo [3/8] Installing frontend dependencies...
cd frontend
call npm install
if %errorlevel% neq 0 (
    echo ERROR: Failed to install frontend dependencies
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✓ Frontend dependencies installed
echo.

REM Step 4: Build frontend
echo [4/8] Building frontend...
cd frontend
call npm run build
if %errorlevel% neq 0 (
    echo ERROR: Failed to build frontend
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✓ Frontend built successfully
echo.

REM Step 5: Copy frontend to backend
echo [5/8] Integrating frontend into backend...
if not exist "backend\src\main\resources\static" mkdir "backend\src\main\resources\static"
xcopy /E /I /Y "frontend\build\*" "backend\src\main\resources\static\"
if %errorlevel% neq 0 (
    echo ERROR: Failed to copy frontend to backend
    pause
    exit /b 1
)
echo ✓ Frontend integrated into backend
echo.

REM Step 6: Build backend
echo [6/8] Building backend...
cd backend
call gradlew.bat clean build -x test
if %errorlevel% neq 0 (
    echo ERROR: Failed to build backend
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✓ Backend built successfully
echo.

REM Step 7: Build Docker image
echo [7/8] Building Docker image...
docker-compose build --no-cache marketstream
if %errorlevel% neq 0 (
    echo ERROR: Failed to build Docker image
    pause
    exit /b 1
)
echo ✓ Docker image built successfully
echo.

REM Step 8: Start complete infrastructure
echo [8/8] Starting MarketStream infrastructure...
echo Starting infrastructure services...
docker-compose up -d zookeeper kafka redis
echo Waiting for infrastructure to be ready...
timeout /t 30 /nobreak >nul

echo Starting MarketStream application...
docker-compose up -d marketstream kafka-ui

echo.
echo ===============================================
echo ✓ MarketStream deployment completed successfully!
echo ===============================================
echo.
echo Access points:
echo - MarketStream Application: http://localhost:8090
echo - Kafka UI: http://localhost:8091
echo - Health Check: http://localhost:8090/actuator/health
echo.
echo Useful commands:
echo - View logs: docker-compose logs -f marketstream
echo - Stop services: docker-compose down
echo - Restart app: docker-compose restart marketstream
echo.
echo Press any key to view logs...
pause >nul
docker-compose logs -f marketstream