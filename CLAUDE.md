# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MarketStream is a real-time market data delivery platform that implements an event-driven architecture using Apache Kafka, Spring Boot, WebSockets, and Redis. The system simulates live financial market data streaming similar to LSEG's RFA product.

## Architecture

- **Backend**: Java 17 Spring Boot application (`backend/`)
- **Frontend**: React 18 application using Parcel bundler (`frontend/`)
- **Infrastructure**: Docker Compose setup with Kafka, Zookeeper, Redis, and Kafka UI

### Key Components
- **Market Data Producer**: Generates simulated market data and publishes to Kafka
- **Market Data Consumer**: Consumes from Kafka and broadcasts via WebSocket
- **WebSocket Controller**: Real-time client connections using STOMP protocol
- **Redis Cache**: Optional caching layer for market data snapshots
- **REST API**: Snapshot endpoints for current market data

## Development Commands

### Quick Start
```bash
# Windows
start.bat                         # Start all services with Docker

# Linux/Mac
./start.sh                        # Start all services with Docker

# Manual Docker
docker-compose up -d              # Start all services
docker-compose logs -f            # View logs
docker-compose down               # Stop all services
```

### Backend (Java/Spring Boot)
```bash
cd backend
./gradlew bootRun                 # Run the Spring Boot application
./gradlew test                    # Run tests
./gradlew build                   # Build the application
./gradlew clean                   # Clean build artifacts
```

### Frontend (React/Parcel)
```bash
cd frontend
npm start                         # Start development server with hot reload
npm run build                     # Build for production
```

### Infrastructure Services
```bash
docker-compose up -d zookeeper kafka redis  # Start infrastructure only
docker-compose up -d marketstream           # Start application
docker-compose ps                           # Check service status
docker-compose logs [service-name]          # View specific service logs
```

## Important Configuration

### Application Profiles
- **Local development**: Uses `application.yml` with localhost connections
- **Docker environment**: Uses `application-docker.yml` with container networking

### Key Environment Variables
- `SPRING_KAFKA_BOOTSTRAP_SERVERS`: Kafka broker addresses
- `SPRING_REDIS_HOST` / `SPRING_REDIS_PORT`: Redis connection
- `SPRING_PROFILES_ACTIVE`: Set to "docker" when running in containers

### Ports
- Backend: `8090`
- Kafka: `9092`
- Redis: `6379`
- Kafka UI: `8091`

## Testing Strategy

The backend uses JUnit 5 with Spring Boot Test. Run tests with:
```bash
cd backend && ./gradlew test
```

## Common Development Workflows

1. **Local Development**: Start Kafka/Redis with Docker, run backend with Gradle, run frontend with npm
2. **Full Stack Testing**: Use `docker-compose up -d` to test the complete system
3. **Debugging**: Check logs via `docker-compose logs` or application logs in `/app/logs/`

## WebSocket Endpoints

- **Connection**: `/ws` (SockJS endpoint)
- **Subscribe to all market data**: `/topic/market-data/all`
- **Subscribe to specific symbol**: `/topic/market-data/{symbol}`

## REST API Endpoints

- `GET /api/market-data/symbols` - Available trading symbols
- `GET /api/market-data/snapshot/{symbol}` - Latest price for symbol
- `GET /api/market-data/snapshots` - All latest prices
- `GET /actuator/health` - Application health check
- `GET /actuator/prometheus` - Metrics for monitoring

## Access Points

### Local Development
- **Application**: http://localhost:8090
- **Kafka UI**: http://localhost:8091  
- **Health Check**: http://localhost:8090/actuator/health

### AWS Production (EC2 i-095de1cc85158decf)
- **Live Demo**: https://marketstream.akashreya.space
- **Health Check**: https://marketstream.akashreya.space/actuator/health
- **Direct IP Access**: http://13.235.117.48:8090 (fallback)
- **Kafka UI**: http://13.235.117.48:8091 (direct port access)

## AWS Deployment

### Quick Deploy Commands
```bash
# Build and deploy in one command
./deploy-quick.sh          # Linux/Mac
deploy-quick.bat           # Windows
```

### AWS Configuration
- **Instance**: t2.micro i-095de1cc85158decf
- **Domain**: marketstream.akashreya.space
- **IP**: 13.235.117.48
- **Region**: ap-south-1 (Mumbai)
- **Docker Hub**: akashreya/marketstream:aws-free-tier
- **Proxy**: Nginx reverse proxy (port 80/443 → 8090)

### Domain Setup
```bash
# On your EC2 instance, run:
sudo ./setup-domain.sh

# Add SSL certificate (optional):
sudo certbot --nginx -d marketstream.akashreya.space
```

### Status Check
```bash
ssh -i akash-instance.pem ec2-user@13.235.117.48 './status.sh'
```