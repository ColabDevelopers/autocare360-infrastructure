# Development Setup Guide

This guide helps developers set up their local environment for working on the AutoCare360 infrastructure and applications.

## Prerequisites

### Required Software
- **Docker**: Version 20.10+ (with Docker Compose)
- **kubectl**: Version 1.24+
- **Kubernetes cluster**: Local (minikube, kind, k3s) or remote
- **Git**: Version 2.30+
- **Make**: GNU Make 4.3+

### Optional Tools
- **kustomize**: For manifest management
- **Helm**: For advanced deployments
- **Lens/K9s**: Kubernetes GUI tools
- **Skaffold**: For continuous development

## Repository Setup

### Clone All Repositories

```bash
# Create workspace directory
mkdir autocare360 && cd autocare360

# Clone infrastructure (this repo)
git clone https://github.com/ColabDevelopers/autocare360-infrastructure.git

# Clone application repositories
git clone https://github.com/ColabDevelopers/dev-autocare360-backend.git
git clone https://github.com/ColabDevelopers/dev-autocare360-frontend.git
git clone https://github.com/ColabDevelopers/autocare360-chatbot.git

# Directory structure
autocare360/
├── autocare360-infrastructure/
├── dev-autocare360-backend/
├── dev-autocare360-frontend/
└── autocare360-chatbot/
```

## Local Kubernetes Setup

### Option 1: Minikube

```bash
# Install Minikube
# Windows (Chocolatey)
choco install minikube

# macOS (Homebrew)
brew install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start --driver=docker

# Enable ingress
minikube addons enable ingress
```

### Option 2: Kind (Kubernetes in Docker)

```bash
# Install Kind
# Windows (Chocolatey)
choco install kind

# macOS (Homebrew)
brew install kind

# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/

# Create cluster with ingress
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

# Install ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml
```

### Option 3: Docker Desktop

Enable Kubernetes in Docker Desktop settings and ensure ingress is enabled.

## Development Workflow

### 1. Build Images

```bash
cd autocare360-infrastructure
make build-all
```

### 2. Deploy to Development

```bash
make deploy-dev
```

### 3. Access Application

```bash
# Add to hosts file (Windows: C:\Windows\System32\drivers\etc\hosts)
echo "127.0.0.1 autocare360.local" | sudo tee -a /etc/hosts

# Open in browser
open http://autocare360.local
```

### 4. Development Loop

```bash
# Make code changes
# Rebuild specific component
make build-backend

# Redeploy
make deploy-dev

# Check logs
kubectl logs -n autocare360 -f deployment/autocare360-backend
```

## Environment Configuration

### Secrets Setup

For local development, update `deployment/kubernetes/base/secrets.yaml` with your credentials:

```bash
# Generate base64 encoded secrets
echo -n "your-mysql-password" | base64
echo -n "your-jwt-secret" | base64
echo -n "your-openai-api-key" | base64
```

### Environment Variables

- **Backend**: Set `SPRING_PROFILES_ACTIVE=dev` in ConfigMap
- **Frontend**: `NEXT_PUBLIC_API_URL` points to backend service
- **Database**: Connection string uses service DNS names

## Debugging

### View Running Pods

```bash
kubectl get pods -n autocare360
kubectl get services -n autocare360
kubectl get ingress -n autocare360
```

### Access Pod Shell

```bash
kubectl exec -n autocare360 -it deployment/autocare360-backend -- /bin/bash
```

### Port Forwarding

```bash
# Access services directly
kubectl port-forward -n autocare360 svc/autocare360-backend-service 8080:8080
kubectl port-forward -n autocare360 svc/mysql-service 3306:3306
```

### View Logs

```bash
# All pods
kubectl logs -n autocare360 --all-containers

# Specific deployment
kubectl logs -n autocare360 -f deployment/autocare360-frontend

# Previous container (after crash)
kubectl logs -n autocare360 -p deployment/autocare360-backend
```

### Database Access

```bash
# Connect to MySQL
kubectl exec -n autocare360 -it deployment/mysql -- mysql -u root -p

# Or port forward and use local client
kubectl port-forward -n autocare360 svc/mysql-service 3306:3306
mysql -h 127.0.0.1 -P 3306 -u user -p autocare360
```

## Testing

### Health Checks

```bash
# Check all endpoints
curl http://autocare360.local/api/actuator/health
curl http://autocare360.local/chat/health
curl http://autocare360.local/  # Frontend
```

### Load Testing

```bash
# Simple load test
for i in {1..10}; do
  curl -s http://autocare360.local/api/actuator/health &
done
wait
```

## Code Changes

### Backend (Java/Spring Boot)

```bash
cd dev-autocare360-backend
# Make changes
mvn compile  # Local compilation
make build-backend  # Docker build
make deploy-dev     # Redeploy
```

### Frontend (Next.js/TypeScript)

```bash
cd dev-autocare360-frontend
# Make changes
npm run build  # Local build
make build-frontend  # Docker build
make deploy-dev      # Redeploy
```

### Chatbot (Python/FastAPI)

```bash
cd autocare360-chatbot
# Make changes
python -m pytest  # Local tests
make build-chatbot  # Docker build
make deploy-dev     # Redeploy
```

## Troubleshooting

### Common Issues

1. **ImagePullBackOff**: Check image exists in registry
   ```bash
   docker images | grep autocare360
   ```

2. **CrashLoopBackOff**: Check pod logs
   ```bash
   kubectl describe pod -n autocare360 <pod-name>
   ```

3. **Service not accessible**: Check ingress and services
   ```bash
   kubectl get ingress -n autocare360
   kubectl describe ingress -n autocare360
   ```

4. **Database connection failed**: Verify secrets and service
   ```bash
   kubectl get secrets -n autocare360
   kubectl describe svc mysql-service -n autocare360
   ```

### Reset Environment

```bash
# Clean restart
make deploy-down
make clean
make deploy-dev
```

## Contributing

1. Create feature branch
2. Make changes following conventions
3. Test locally with `make validate`
4. Submit PR with description
5. CI/CD will run automated tests