# AutoCare360 Infrastructure

This repository contains the infrastructure-as-code for deploying the AutoCare360 application stack, which includes:

- **Frontend**: Next.js-based web application
- **Backend**: Java Spring Boot API server
- **Chatbot**: Python FastAPI-based AI assistant
- **Database**: MySQL database with persistent storage

## Documentation

- [Quick Start](README.md#quick-start)
- [Kubernetes Deployment](docs/KUBERNETES.md)
- [Docker Builds](docs/DOCKER.md)
- [Development Setup](docs/DEVELOPMENT.md)
- [GitHub Secrets Setup](docs/GITHUB_SECRETS.md)

## Architecture

The application is containerized and deployed to Kubernetes with the following components:

- **Namespace**: `autocare360`
- **Ingress**: Path-based routing on `autocare360.local`
  - `/` → Frontend (port 3000)
  - `/api` → Backend (port 8080)
  - `/chat` → Chatbot (port 8000)
- **Database**: MySQL 8.0 with persistent storage
- **Cache**: Redis 7 for session management and caching
- **Security**: RBAC, secrets management, non-root containers

## Prerequisites

- Docker and Docker Compose
- Kubernetes cluster (local: minikube/kind, cloud: EKS/GKE/AKS)
- kubectl configured
- GitHub Container Registry access (for pulling images)

## Quick Start

### Local Development

1. **Clone all repositories**:
   ```bash
   git clone https://github.com/ColabDevelopers/autocare360-infrastructure.git
   git clone https://github.com/ColabDevelopers/dev-autocare360-backend.git
   git clone https://github.com/ColabDevelopers/dev-autocare360-frontend.git
   git clone https://github.com/ColabDevelopers/autocare360-chatbot.git
   ```

2. **Configure GitHub Secrets** (for production deployment):
   See [GitHub Secrets Setup](docs/GITHUB_SECRETS.md) for detailed instructions on configuring secrets for automated deployment.

3. **Update secrets** (for local development - optional):
   Edit `deployment/kubernetes/base/secrets.yaml` with your actual credentials, or use the provided defaults.

3. **Deploy to local cluster**:
   ```bash
   make deploy-dev
   ```

4. **Access the application**:
   - Add to `/etc/hosts`: `127.0.0.1 autocare360.local`
   - Open http://autocare360.local

5. **Stop deployment**:
   ```bash
   make deploy-down
   ```

### Production Deployment

1. **Build and tag images**:
   ```bash
   make build-all
   # Tag with version: docker tag ...:latest ...:v1.0.0
   ```

2. **Push images to registry**:
   ```bash
   docker push ghcr.io/colabdevelopers/dev-autocare360-backend:latest
   docker push ghcr.io/colabdevelopers/dev-autocare360-frontend:latest
   docker push ghcr.io/colabdevelopers/autocare360-chatbot:latest
   ```

3. **Deploy to production**:
   ```bash
   make deploy-prod
   ```

## Configuration

### Secrets Management

Secrets are stored in `deployment/kubernetes/base/secrets.yaml`. Update with base64-encoded values:

```bash
echo -n "your-secret" | base64
```

Required secrets:
- `MYSQL_ROOT_PASSWORD`
- `MYSQL_DATABASE`
- `MYSQL_USER`
- `MYSQL_PASSWORD`
- `DB_URL`
- `JWT_SECRET`
- `OPENAI_API_KEY`

### Environment Variables

- **Backend**: Configured via ConfigMap (`SPRING_PROFILES_ACTIVE`)
- **Frontend**: `NEXT_PUBLIC_API_URL` points to backend service
- **Chatbot**: Database and OpenAI credentials via secrets

## Development

### Building Individual Components

```bash
make build-backend    # Build backend image
make build-frontend   # Build frontend image
make build-chatbot    # Build chatbot image
make build-all        # Build all images
```

### Validation

Validate manifests without applying:
```bash
make validate
```

### Cleanup

Remove Docker images:
```bash
make clean
```

## Monitoring

The backend includes Prometheus metrics at `/actuator/prometheus` and health checks at `/actuator/health`.

## Troubleshooting

### Common Issues

1. **Image pull errors**: Ensure images are pushed to registry and accessible
2. **Database connection**: Check MySQL service and secrets
3. **Cache connection**: Verify Redis service is running and accessible
4. **Ingress not working**: Verify ingress controller is installed (e.g., `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml`)

### Logs

View pod logs:
```bash
kubectl logs -n autocare360 deployment/autocare360-backend
kubectl logs -n autocare360 deployment/autocare360-frontend
kubectl logs -n autocare360 deployment/autocare360-chatbot
kubectl logs -n autocare360 deployment/mysql
kubectl logs -n autocare360 deployment/redis
```

### Port Forwarding (for debugging)

```bash
kubectl port-forward -n autocare360 svc/autocare360-frontend-service 3000:3000
kubectl port-forward -n autocare360 svc/autocare360-backend-service 8080:8080
kubectl port-forward -n autocare360 svc/autocare360-chatbot-service 8000:8000
kubectl port-forward -n autocare360 svc/mysql-service 3306:3306
kubectl port-forward -n autocare360 svc/redis-service 6379:6379
```

## Contributing

1. Make changes to manifests in `deployment/kubernetes/`
2. Test with `make validate`
3. Update documentation as needed
4. Submit PR with description of changes

## License

See LICENSE file in root directory.