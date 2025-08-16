# MarketStream: Real-Time Market Data Platform

A modern, cloud-native event-driven system that delivers real-time financial market data using Apache Kafka, Spring Boot, WebSockets, and Redis.

## 🚀 Quick Start

### Prerequisites
- Docker Desktop (running)
- Java 21+ and Node.js 18+ (for builds)

### Option 1: Complete Production Build (Recommended)
```bash
# Windows - builds everything and starts all services
build-and-run.bat

# Linux/Mac - builds everything and starts all services
./build-and-run.sh

# Access: http://localhost:8090 (integrated frontend + backend)
```

### Option 2: Development Mode (Hot Reload)
```bash
# Windows - separate frontend/backend with hot reload
dev.bat

# Linux/Mac - separate frontend/backend with hot reload  
./dev.sh

# Frontend: http://localhost:1234, Backend: http://localhost:8090
```

### Option 3: AWS Free Tier Deployment (Portfolio Showcase)
```bash
# Build all-in-one container optimized for t2.micro
./build-aws.sh

# Deploy to AWS Free Tier (zero cost)
./deploy-to-aws.sh

# Access: http://your-ec2-public-ip:8090
```

### Option 4: Docker Only (Legacy)
```bash
# Just run pre-built containers
docker-compose up -d

# Access: http://localhost:8090, Kafka UI: http://localhost:8091
```

📖 **Build Instructions**: [BUILD-GUIDE.md](BUILD-GUIDE.md) | **AWS Deployment**: [AWS-DEPLOYMENT.md](AWS-DEPLOYMENT.md)

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Market    │───▶│    Kafka    │───▶│  WebSocket  │───▶│   React     │
│ Data Producer│    │  Streaming  │    │  Consumers  │    │  Frontend   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                           │
                           ▼
                  ┌─────────────┐
                  │    Redis    │
                  │   Caching   │
                  └─────────────┘
```

## 🔧 Recent Fixes

### Infrastructure Issues Resolved
- ✅ **Created Dockerfile**: Proper Java 21 containerization for backend
- ✅ **Fixed Docker Compose**: Clean configuration with health checks
- ✅ **Added Docker Profile**: Container-specific application configuration
- ✅ **Service Dependencies**: Proper startup order with health checks

### Configuration Improvements
- ✅ **Container Networking**: Fixed Kafka/Redis connection for Docker environment
- ✅ **Health Checks**: Added comprehensive service health monitoring
- ✅ **Error Handling**: Improved resilience and retry logic
- ✅ **Logging**: Enhanced logging for debugging and monitoring

## 📊 Features

### Real-Time Data Streaming
- Live market data for 10 major stocks (AAPL, GOOGL, MSFT, etc.)
- WebSocket connections with auto-reconnect
- Visual price change indicators with flash effects

### REST API Endpoints
- `GET /api/market-data/symbols` - Available symbols
- `GET /api/market-data/snapshot/{symbol}` - Latest price for symbol
- `GET /api/market-data/snapshots` - All latest prices
- `GET /actuator/health` - Application health check

### WebSocket Endpoints
- `/ws` - SockJS connection endpoint
- `/topic/market-data/all` - Subscribe to all market updates
- `/topic/market-data/{symbol}` - Subscribe to specific symbol

## 🧪 Testing the System

### 1. Verify Infrastructure
```bash
# Check all services are running
docker-compose ps

# Test Kafka connection
docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic market-data-topic

# Test Redis connection
docker-compose exec redis redis-cli ping
```

### 2. Test Data Flow
1. **Market Data Generation**: Check logs for producer messages
2. **Kafka Streaming**: Monitor Kafka UI at http://localhost:8090
3. **WebSocket Broadcasting**: Connect frontend and watch real-time updates
4. **Caching**: Verify Redis caching of latest market data

### 3. Frontend Testing
1. Open http://localhost:8090
2. Click "Connect" to start WebSocket connection
3. Verify real-time price updates with visual indicators
4. Test "Load Initial Data" for REST API functionality

## 🐛 Troubleshooting

### Common Issues

**Docker Services Won't Start**
```bash
# Check Docker is running
docker ps

# View service logs
docker-compose logs [service-name]

# Restart services
docker-compose restart
```

**Backend Can't Connect to Kafka**
- Ensure Kafka service is healthy: `docker-compose ps`
- Check Kafka logs: `docker-compose logs kafka`
- Verify ports are not in use: `netstat -an | findstr 9092`

**Frontend WebSocket Connection Failed**
- Verify backend is running and healthy
- Check browser console for errors
- Test health endpoint: http://localhost:8090/actuator/health

## 📈 Performance & Scaling

### Current Capacity
- **Message Throughput**: 10 messages/second (1 per symbol)
- **WebSocket Connections**: Supports multiple concurrent clients
- **Caching**: Redis with in-memory fallback

### Scaling Options
- **Kafka Partitions**: Increase for parallel processing
- **Consumer Groups**: Deploy multiple consumer instances  
- **Load Balancing**: Add nginx for multiple app instances
- **Database**: Add persistent storage for historical data

## 🔐 Production Considerations

### Security (TODO)
- [ ] Add authentication/authorization
- [ ] Implement rate limiting
- [ ] Enable HTTPS/WSS
- [ ] Secure container images

### Monitoring (Partial)
- ✅ Health checks and metrics
- ✅ Prometheus integration
- [ ] Distributed tracing
- [ ] Alert management

### Reliability
- ✅ Service health checks
- ✅ Auto-restart policies
- ✅ Graceful error handling
- [ ] Circuit breakers
- [ ] Backup/recovery procedures

## 📝 Development

### Backend (Spring Boot)
```bash
cd backend
./gradlew test          # Run tests
./gradlew build         # Build application
./gradlew bootRun       # Run locally
```

### Frontend (React/Parcel)
```bash
cd frontend
npm test               # Run tests (if available)
npm run build          # Build for production
npm start              # Development server
```

## 🎯 Next Steps

1. **Production Deployment**: Configure for cloud environments
2. **Authentication**: Add user management and API security
3. **Historical Data**: Implement data persistence and querying
4. **Advanced Features**: Add charting, alerts, and portfolio tracking
5. **Performance Testing**: Load testing with multiple concurrent users

## 🎯 Portfolio Showcase Features

### Professional Deployment Options
- **AWS Free Tier**: Production-ready deployment at zero cost
- **Single Container**: All services optimized for t2.micro (1 vCPU, 1GB RAM)
- **Cost Monitoring**: Built-in cost control and optimization
- **Scalable Architecture**: Demonstrates cloud-native design principles

### Technical Highlights
- **Event-Driven Architecture**: Kafka-based real-time data streaming
- **Microservices Integration**: Spring Boot + React + Redis + Kafka
- **Container Optimization**: Memory-efficient multi-service container
- **DevOps Automation**: One-command build and deployment
- **Resource Management**: Optimized for constrained environments

### Live Demo
Deploy to AWS Free Tier in under 5 minutes:
```bash
./build-aws.sh && ./deploy-to-aws.sh
```

**Perfect for**: Technical interviews, client demos, portfolio presentations

## 📄 License

MIT License - see LICENSE file for details.