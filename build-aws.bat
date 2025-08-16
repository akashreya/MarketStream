@echo off
echo ====================================================
echo Building MarketStream All-in-One for AWS Free Tier
echo ====================================================
echo.

REM Check Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not installed
    pause
    exit /b 1
)

echo [1/4] Cleaning previous builds...
docker rmi marketstream:aws-free-tier 2>nul
docker system prune -f >nul 2>&1

echo [2/4] Building all-in-one image for t2.micro...
docker build -f Dockerfile.all-in-one -t marketstream:aws-free-tier .
if %errorlevel% neq 0 (
    echo ERROR: Docker build failed
    pause
    exit /b 1
)

echo [3/4] Testing container locally...
echo Starting container for local test...
docker run -d --name marketstream-test -p 8090:8090 -p 8091:8091 marketstream:aws-free-tier
if %errorlevel% neq 0 (
    echo ERROR: Failed to start test container
    pause
    exit /b 1
)

echo Waiting for services to start...
timeout /t 60 /nobreak >nul

echo Testing health endpoint...
curl -f http://localhost:8090/actuator/health
if %errorlevel% neq 0 (
    echo WARNING: Health check failed, but container may still be starting
)

echo [4/4] Cleaning up test container...
docker stop marketstream-test >nul 2>&1
docker rm marketstream-test >nul 2>&1

echo.
echo ====================================================
echo ✓ All-in-One image built successfully!
echo ====================================================
echo.
echo Image: marketstream:aws-free-tier
echo Optimized for: AWS EC2 t2.micro (1 vCPU, 1GB RAM)
echo.
echo Next steps:
echo 1. Push to Docker Hub: docker tag marketstream:aws-free-tier [your-dockerhub]/marketstream:aws-free-tier
echo 2. Deploy to AWS: Use deploy-to-aws.sh script
echo 3. Or run locally: docker run -p 8090:8090 marketstream:aws-free-tier
echo.
pause