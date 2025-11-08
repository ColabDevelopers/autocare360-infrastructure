# Docker Build Guide

This document explains how to build and manage Docker images for the AutoCare360 application stack.

## Images Overview

| Component | Base Image | Build Context | Exposed Port |
|-----------|------------|---------------|--------------|
| Frontend | node:18-alpine | dev-autocare360-frontend/ | 3000 |
| Backend | openjdk:17-jdk-slim | dev-autocare360-backend/ | 8080 |
| Chatbot | python:3.11-slim | autocare360-chatbot/ | 8000 |
| Database | mysql:8.0 | N/A (official image) | 3306 |

## Building Images

### Individual Builds

```bash
# Frontend
cd dev-autocare360-frontend
docker build -t ghcr.io/colabdevelopers/dev-autocare360-frontend:latest .

# Backend
cd dev-autocare360-backend
docker build -t ghcr.io/colabdevelopers/dev-autocare360-backend:latest .

# Chatbot
cd autocare360-chatbot
docker build -t ghcr.io/colabdevelopers/autocare360-chatbot:latest .
```

### Multi-Architecture Builds

For production deployments on different architectures:

```bash
# Build for multiple platforms
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/colabdevelopers/dev-autocare360-frontend:latest \
  --push .
```

## Image Optimization

### Frontend (Next.js)
- Multi-stage build reduces final image size
- Production build with `next build`
- Static file serving with nginx

### Backend (Spring Boot)
- Layered JAR for faster startup
- JRE instead of JDK in final image
- Alpine-based for smaller size

### Chatbot (Python)
- Virtual environment isolation
- Multi-stage build with dependencies
- Non-root user execution

## Registry Management

### GitHub Container Registry

1. **Authenticate**:
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

2. **Push images**:
   ```bash
   docker push ghcr.io/colabdevelopers/dev-autocare360-frontend:latest
   docker push ghcr.io/colabdevelopers/dev-autocare360-backend:latest
   docker push ghcr.io/colabdevelopers/autocare360-chatbot:latest
   ```

3. **Pull images**:
   ```bash
   docker pull ghcr.io/colabdevelopers/dev-autocare360-frontend:latest
   ```

### Tagging Strategy

- **Latest**: `latest` (development)
- **Versioned**: `v1.0.0`, `v1.1.0` (releases)
- **Git SHA**: `git-$(git rev-parse --short HEAD)` (CI/CD)

## Local Development

### Docker Compose (Alternative)

For local development without Kubernetes:

```yaml
# docker-compose.yml
version: '3.8'
services:
  frontend:
    build: ../dev-autocare360-frontend
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8080

  backend:
    build: ../dev-autocare360-backend
    ports:
      - "8080:8080"
    environment:
      - DB_URL=jdbc:mysql://mysql:3306/autocare360
    depends_on:
      - mysql

  chatbot:
    build: ../autocare360-chatbot
    ports:
      - "8000:8000"
    environment:
      - DB_URL=mysql://user:pass@mysql:3306/autocare360

  mysql:
    image: mysql:8.0
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=rootpass
      - MYSQL_DATABASE=autocare360
      - MYSQL_USER=user
      - MYSQL_PASSWORD=pass
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
```

### Development Workflow

1. **Build images**:
   ```bash
   make build-all
   ```

2. **Run locally**:
   ```bash
   docker-compose up -d
   ```

3. **View logs**:
   ```bash
   docker-compose logs -f
   ```

4. **Clean up**:
   ```bash
   docker-compose down -v
   ```

## Troubleshooting

### Build Issues

**Frontend build fails**:
- Check Node.js version compatibility
- Ensure all dependencies are in `package.json`
- Verify build scripts in `package.json`

**Backend build fails**:
- Check Java version (17 required)
- Ensure Maven wrapper is present
- Verify `pom.xml` dependencies

**Chatbot build fails**:
- Check Python version (3.11 required)
- Ensure `requirements.txt` is complete
- Verify `src/` structure

### Image Size Optimization

- Use `.dockerignore` to exclude unnecessary files
- Leverage multi-stage builds
- Use smaller base images (alpine, slim variants)
- Clean up package manager caches

### Security Scanning

```bash
# Scan images for vulnerabilities
docker scan ghcr.io/colabdevelopers/dev-autocare360-backend:latest

# Or use Trivy
trivy image ghcr.io/colabdevelopers/dev-autocare360-backend:latest
```

## CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/build.yml
name: Build and Push Images
on:
  push:
    branches: [ main ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Frontend
        run: |
          cd dev-autocare360-frontend
          docker build -t ghcr.io/colabdevelopers/dev-autocare360-frontend:${{ github.sha }} .
      - name: Push Frontend
        run: |
          echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker push ghcr.io/colabdevelopers/dev-autocare360-frontend:${{ github.sha }}
```