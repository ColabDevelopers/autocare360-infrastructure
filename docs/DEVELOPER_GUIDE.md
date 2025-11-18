# AutoCare360 Developer Guide

This guide provides comprehensive instructions for developers to set up and run the AutoCare360 project locally for development purposes.

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Prerequisites](#-prerequisites)
- [Project Structure](#-project-structure)
- [Local Development Setup](#-local-development-setup)
- [Running Individual Services](#-running-individual-services)
- [Kubernetes Development](#-kubernetes-development)
- [Development Workflow](#-development-workflow)
- [Debugging and Troubleshooting](#-debugging-and-troubleshooting)
- [Testing](#-testing)
- [Code Standards](#-code-standards)

## 🔍 Project Overview

AutoCare360 is a comprehensive automotive service management system consisting of:

- **Frontend**: Next.js 14 application with TypeScript and Tailwind CSS
- **Backend**: Spring Boot 3.5.6 application with Java 21
- **Chatbot**: FastAPI-based AI chatbot with RAG capabilities
- **Infrastructure**: Kubernetes deployment configurations

### Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │    Chatbot      │
│   (Next.js)     │◄──►│  (Spring Boot)  │◄──►│   (FastAPI)     │
│   Port: 3000    │    │   Port: 8080    │    │   Port: 8000    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │     MySQL       │
                    │   Port: 3306    │
                    └─────────────────┘
```

## 📋 Prerequisites

### Required Software

1. **Git**: Version control
   ```bash
   git --version
   ```

2. **Docker Desktop**: For containerization
   - Download from [Docker Desktop](https://www.docker.com/products/docker-desktop/)
   - Enable Kubernetes in Docker Desktop settings
   ```bash
   docker --version
   docker-compose --version
   ```

3. **Node.js 18+**: For frontend development
   ```bash
   node --version
   npm --version
   ```

4. **pnpm**: Package manager (recommended for frontend)
   ```bash
   npm install -g pnpm
   pnpm --version
   ```

5. **Java 21**: For backend development
   ```bash
   java --version
   ```

6. **Maven 3.9+**: For backend builds
   ```bash
   mvn --version
   ```

7. **Python 3.9+**: For chatbot development
   ```bash
   python --version
   pip --version
   ```

8. **kubectl**: Kubernetes CLI
   ```bash
   kubectl version --client
   ```

### Optional Tools

- **VS Code** or **IntelliJ IDEA**: Recommended IDEs
- **Postman** or **Insomnia**: API testing
- **MySQL Workbench**: Database management

## 🏗️ Project Structure

```
autocare360/
├── autocare360-infrastructure/     # Kubernetes configs & DevOps
├── dev-autocare360-frontend/       # Next.js frontend
├── dev-autocare360-backend/        # Spring Boot backend
└── autocare360-chatbot/           # FastAPI chatbot
```

## 🚀 Local Development Setup

### Option 1: Docker Compose (Recommended for Full Stack)

1. **Clone all repositories**:
   ```bash
   git clone https://github.com/ColabDevelopers/autocare360-infrastructure.git
   git clone https://github.com/ColabDevelopers/dev-autocare360-frontend.git
   git clone https://github.com/ColabDevelopers/dev-autocare360-backend.git
   git clone https://github.com/ColabDevelopers/autocare360-chatbot.git
   ```

2. **Setup environment variables for each service**:

   **Backend** (`dev-autocare360-backend/.env`):
   ```env
   # Database
   MYSQL_ROOT_PASSWORD=rootpassword123
   MYSQL_DATABASE=autocare360
   MYSQL_USER=autocare360_user
   MYSQL_PASSWORD=userpassword123
   
   # Application
   SPRING_PROFILES_ACTIVE=dev
   JWT_SECRET=your-256-bit-secret-key-here
   
   # CORS
   CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000
   ```

   **Frontend** (`dev-autocare360-frontend/.env.local`):
   ```env
   NEXT_PUBLIC_API_URL=http://localhost:8080
   NEXT_PUBLIC_CHATBOT_URL=http://localhost:8000
   NEXT_PUBLIC_WS_URL=ws://localhost:8080
   ```

   **Chatbot** (`autocare360-chatbot/.env`):
   ```env
   # AI Provider (choose one)
   OPENAI_API_KEY=your-openai-api-key
   # OR
   GOOGLE_API_KEY=your-gemini-api-key
   # OR
   GROK_API_KEY=your-grok-api-key
   
   # Database
   DATABASE_URL=mysql+pymysql://autocare360_user:userpassword123@mysql:3306/autocare360
   
   # Application
   ENV=development
   DEBUG=true
   ```

3. **Start all services**:
   ```bash
   # Start backend with database
   cd dev-autocare360-backend
   docker-compose --env-file .env up --build -d
   
   # Start chatbot
   cd ../autocare360-chatbot
   docker-compose --env-file .env up --build -d
   
   # Start frontend (development mode)
   cd ../dev-autocare360-frontend
   pnpm install
   pnpm dev
   ```

4. **Access the application**:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8080
   - Chatbot API: http://localhost:8000
   - Database: localhost:3306

### Option 2: Individual Service Development

For developing specific services independently:

#### Frontend Development

```bash
cd dev-autocare360-frontend

# Install dependencies
pnpm install

# Start development server
pnpm dev

# Build for production
pnpm build

# Start production server
pnpm start
```

#### Backend Development

```bash
cd dev-autocare360-backend

# Start MySQL database
docker-compose up mysql -d

# Run application (make sure Java 21 is active)
mvn spring-boot:run

# Or with specific profile
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

#### Chatbot Development

```bash
cd autocare360-chatbot

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows
venv\Scripts\activate
# Linux/Mac
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start development server
python -m uvicorn src.main.main:app --reload --port 8000
```

## 🐳 Kubernetes Development

For testing Kubernetes deployments locally:

1. **Navigate to infrastructure**:
   ```bash
   cd autocare360-infrastructure
   ```

2. **Setup environment**:
   ```bash
   # Copy environment template
   copy .env.example .env

   # Edit .env with your values
   notepad .env
   ```

3. **Deploy to local Kubernetes**:
   ```bash
   # Create namespace and secrets
   make setup

   # Or manually:
   kubectl create namespace autocare360
   kubectl create secret generic autocare360-secrets --from-env-file=.env -n autocare360
   kubectl apply -k deployment/kubernetes/overlays/dev
   ```

4. **Access services**:
   ```bash
   # Start port forwarding
   make start

   # Or manually in separate terminals:
   kubectl port-forward -n autocare360 svc/autocare360-frontend-service 3000:80
   kubectl port-forward -n autocare360 svc/autocare360-backend-service 8080:8080
   kubectl port-forward -n autocare360 svc/autocare360-chatbot-service 8000:8000
   ```

## 🔄 Development Workflow

### 1. Feature Development

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and test locally
# ... development work ...

# Run tests
pnpm test              # Frontend
mvn test              # Backend
pytest                # Chatbot

# Commit changes
git add .
git commit -m "feat: add your feature description"

# Push and create PR
git push origin feature/your-feature-name
```

### 2. Code Quality

**Frontend**:
```bash
# Lint code
pnpm lint

# Format code
pnpm format

# Type check
pnpm type-check
```

**Backend**:
```bash
# Run tests
mvn test

# Check code style
mvn checkstyle:check

# Build
mvn clean package
```

**Chatbot**:
```bash
# Format code
black src/
isort src/

# Lint code
flake8 src/

# Run tests
pytest
```

## 🐛 Debugging and Troubleshooting

### Common Issues

1. **Port conflicts**:
   ```bash
   # Check what's using a port
   netstat -ano | findstr :3000
   
   # Kill process by PID
   taskkill /PID <PID> /F
   ```

2. **Docker issues**:
   ```bash
   # Reset Docker
   docker system prune -a
   docker volume prune
   
   # Rebuild containers
   docker-compose down
   docker-compose up --build
   ```

3. **Database connection issues**:
   ```bash
   # Check MySQL container
   docker-compose logs mysql
   
   # Connect to database
   docker-compose exec mysql mysql -u root -p
   ```

4. **Kubernetes issues**:
   ```bash
   # Check pod status
   kubectl get pods -n autocare360
   
   # Check logs
   kubectl logs -f deployment/autocare360-backend -n autocare360
   
   # Describe pod for detailed info
   kubectl describe pod <pod-name> -n autocare360
   ```

### Debugging Tools

1. **Frontend Debugging**:
   - Browser DevTools
   - React DevTools extension
   - Next.js debugging: Set `NODE_OPTIONS='--inspect'`

2. **Backend Debugging**:
   - IntelliJ IDEA debugger
   - VS Code Java extension
   - Spring Boot Actuator endpoints: http://localhost:8080/actuator/health

3. **Chatbot Debugging**:
   - FastAPI interactive docs: http://localhost:8000/docs
   - Python debugger (pdb)
   - Uvicorn reload mode for live changes

## 🧪 Testing

### Frontend Testing

```bash
# Run all tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Run tests with coverage
pnpm test:coverage

# Run e2e tests
pnpm test:e2e
```

### Backend Testing

```bash
# Run unit tests
mvn test

# Run integration tests
mvn verify

# Run specific test class
mvn test -Dtest=UserServiceTest

# Run with coverage
mvn jacoco:report
```

### Chatbot Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src

# Run specific test file
pytest tests/test_api.py

# Run with verbose output
pytest -v
```

### Integration Testing

```bash
# Start all services
docker-compose -f docker-compose.test.yml up --build

# Run integration tests
# (Add your integration test commands here)
```

## 📝 Code Standards

### Frontend Standards

- **TypeScript**: Strict mode enabled
- **ESLint**: Airbnb configuration
- **Prettier**: Code formatting
- **Naming**: PascalCase for components, camelCase for variables
- **File structure**: Feature-based organization

### Backend Standards

- **Java**: Version 21
- **Spring Boot**: Latest stable version
- **Code style**: Google Java Style Guide
- **Testing**: JUnit 5 with Mockito
- **Documentation**: JavaDoc for public APIs

### Chatbot Standards

- **Python**: Version 3.9+
- **Code style**: PEP 8
- **Formatting**: Black
- **Import sorting**: isort
- **Linting**: flake8
- **Type hints**: Required for all functions

### Git Workflow

- **Commit messages**: Follow conventional commits
- **Branch naming**: `feature/`, `bugfix/`, `hotfix/`
- **Pull requests**: Required for all changes
- **Code review**: At least one approval required

## 🔗 Useful Links

- [Frontend Documentation](../dev-autocare360-frontend/README.md)
- [Backend Documentation](../dev-autocare360-backend/README.md)
- [Chatbot Documentation](../autocare360-chatbot/src/README.md)
- [DevOps Guide](DEVOPS_GUIDE.md)
- [API Documentation](../dev-autocare360-backend/docs/openapi.yaml)

## 📞 Getting Help

1. **Check existing documentation**
2. **Search GitHub issues**
3. **Create a new issue** with:
   - Environment details
   - Steps to reproduce
   - Expected vs actual behavior
   - Logs/screenshots

Happy coding! 🚀