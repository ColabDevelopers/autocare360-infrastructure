# Kubernetes Deployment Guide

This document provides detailed information about the Kubernetes deployment setup for AutoCare360.

## Directory Structure

```
deployment/kubernetes/
├── base/                    # Base manifests
│   ├── namespace.yaml       # Namespace definition
│   ├── secrets.yaml         # Application secrets
│   ├── configmap.yaml       # Configuration
│   ├── backend-deployment.yaml    # Backend deployment
│   ├── backend-service.yaml       # Backend service
│   ├── frontend-deployment.yaml   # Frontend deployment
│   ├── frontend-service.yaml      # Frontend service
│   ├── chatbot-deployment.yaml    # Chatbot deployment
│   ├── chatbot-service.yaml       # Chatbot service
│   ├── db-redis-deployment.yaml   # Redis deployment
│   ├── db-redis-service.yaml      # Redis service
│   ├── db-mysql-deployment.yaml   # MySQL deployment
│   ├── db-mysql-service.yaml      # MySQL service
│   ├── storage/             # Persistent storage
│   ├── network/             # Ingress configuration
│   └── rbac/                # RBAC policies
├── overlays/                # Environment-specific overlays
│   └── dev/                 # Development environment
│       ├── kustomization.yaml
│       └── patch.yaml       # Development patches
└── kustomization.yaml       # Root kustomization
```

## Components

### Frontend (Next.js)
- **Image**: `ghcr.io/colabdevelopers/dev-autocare360-frontend:latest`
- **Port**: 3000
- **Health Checks**: HTTP GET on `/`
- **Resources**: 100m CPU, 256Mi RAM (requests); 200m CPU, 512Mi RAM (limits)

### Backend (Spring Boot)
- **Image**: `ghcr.io/colabdevelopers/dev-autocare360-backend:latest`
- **Port**: 8080
- **Health Checks**: HTTP GET on `/actuator/health`
- **Metrics**: Prometheus endpoint at `/actuator/prometheus`
- **Resources**: 250m CPU, 512Mi RAM (requests); 500m CPU, 1Gi RAM (limits)

### Chatbot (FastAPI)
- **Image**: `ghcr.io/colabdevelopers/autocare360-chatbot:latest`
- **Port**: 8000
- **Health Checks**: HTTP GET on `/health`
- **Resources**: 100m CPU, 256Mi RAM (requests); 200m CPU, 512Mi RAM (limits)

### Database (MySQL)
- **Image**: `mysql:8.0`
- **Port**: 3306
- **Storage**: 10Gi PVC
- **Health Checks**: mysqladmin ping
- **Resources**: 250m CPU, 512Mi RAM (requests); 500m CPU, 1Gi RAM (limits)

### Cache (Redis)
- **Image**: `redis:7-alpine`
- **Port**: 6379
- **Storage**: 5Gi PVC for persistence
- **Configuration**: Append-only file enabled
- **Resources**: 100m CPU, 128Mi RAM (requests); 200m CPU, 256Mi RAM (limits)

## Networking

### Ingress Configuration
- **Host**: `autocare360.local`
- **Paths**:
  - `/` → Frontend service
  - `/api` → Backend service
  - `/chat` → Chatbot service

### Service Discovery
All services communicate internally using Kubernetes DNS:
- `autocare360-backend-service.autocare360.svc.cluster.local:8080`
- `autocare360-frontend-service.autocare360.svc.cluster.local:3000`
- `autocare360-chatbot-service.autocare360.svc.cluster.local:8000`
- `mysql-service.autocare360.svc.cluster.local:3306`
- `redis-service.autocare360.svc.cluster.local:6379`

## Security

### RBAC
- Service account `autocare360-sa` with read access to secrets
- Role-based access control for namespace-scoped resources

### Secrets Management
- All sensitive data stored in Kubernetes secrets
- Base64 encoded values
- Mounted as environment variables

### Container Security
- Non-root user execution (UID 1000)
- Read-only root filesystem where possible
- Resource limits and requests defined

## Storage

### MySQL Persistent Volume
- **Type**: ReadWriteOnce
- **Size**: 10Gi
- **Access Mode**: Single node
- **Reclaim Policy**: Retain (in production)

### Redis Persistent Volume
- **Type**: ReadWriteOnce
- **Size**: 5Gi
- **Access Mode**: Single node
- **Purpose**: Redis append-only file persistence

## Scaling

Current setup uses 1 replica per deployment. To scale:

```bash
kubectl scale deployment autocare360-backend -n autocare360 --replicas=3
```

## Monitoring

### Health Checks
- **Liveness**: Container restart if unhealthy
- **Readiness**: Traffic routing when ready

### Metrics
- Backend exposes Spring Boot Actuator metrics
- Prometheus annotations configured

## Environment Overrides

### Development
- `imagePullPolicy: Never` (use local images)
- `SPRING_PROFILES_ACTIVE: dev`

### Production
- `imagePullPolicy: Always` (pull latest)
- `SPRING_PROFILES_ACTIVE: prod`
- Higher resource limits
- Multiple replicas