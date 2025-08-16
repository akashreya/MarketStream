@echo off
echo 🚀 Quick Deploy to AWS EC2
echo Instance: i-095de1cc85158decf (13.235.117.48)
echo ==================================================

REM Build and push to Docker Hub
echo Step 1: Building and pushing to Docker Hub...
call build-aws.bat
docker push akashreya/marketstream:aws-free-tier

REM Deploy to EC2
echo Step 2: Deploying to EC2...
ssh -i akash-instance.pem -o StrictHostKeyChecking=no ec2-user@13.235.117.48 ^
"docker stop marketstream 2>/dev/null; ^
docker rm marketstream 2>/dev/null; ^
docker pull akashreya/marketstream:aws-free-tier; ^
docker run -d --name marketstream --restart unless-stopped -p 8090:8090 -p 8091:8091 akashreya/marketstream:aws-free-tier; ^
echo Container started, waiting for services...; ^
timeout /t 10; ^
docker logs --tail 20 marketstream"

echo ✅ Deployment Complete!
echo.
echo 🌐 Your live application:
echo    MarketStream: https://marketstream.akashreya.space
echo    Direct IP: http://13.235.117.48:8090
echo    Kafka UI: http://13.235.117.48:8091
echo.
echo 📋 Commands:
echo    Status: ssh -i akash-instance.pem ec2-user@13.235.117.48 "./status.sh"
echo    Setup Domain: ssh -i akash-instance.pem ec2-user@13.235.117.48 "sudo ./setup-domain.sh"
echo.
pause