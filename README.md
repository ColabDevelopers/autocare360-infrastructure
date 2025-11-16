# AutoCare360 Kubernetes Infrastructure

Complete Kubernetes deployment configuration for AutoCare360 with proper environment variable management.

## 🚀 Quick Start (Development)

### Step 1: Setup Environment Variables

```powershell
# Copy the environment template
copy .env.example .env
```

**Edit `.env`** with your actual values:
- Replace `MYSQL_ROOT_PASSWORD` with a secure password
- Replace `MYSQL_PASSWORD` with a secure password  
- Replace `JWT_SECRET` with a strong secret (min 256 bits)
- Replace `OPENAI_API_KEY` with your OpenAI API key (or other AI provider keys)
- Update any other placeholder values as needed

### Step 2: Create Kubernetes Namespace

```powershell
kubectl create namespace autocare360
```

### Step 3: Create Secrets

```powershell
kubectl create secret generic autocare360-secrets `
  --from-env-file=.env `
  -n autocare360
```

### Step 4: Deploy to Kubernetes

```powershell
kubectl apply -k deployment\kubernetes\overlays\dev
```

### Step 5: Wait for Pods to be Ready

```powershell
# Check status
kubectl get pods -n autocare360

# Wait for all pods to be Running
kubectl wait --for=condition=ready pod -l app=mysql -n autocare360 --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n autocare360 --timeout=300s
kubectl wait --for=condition=ready pod -l app=autocare360-backend -n autocare360 --timeout=300s
kubectl wait --for=condition=ready pod -l app=autocare360-frontend -n autocare360 --timeout=300s
kubectl wait --for=condition=ready pod -l app=autocare360-chatbot -n autocare360 --timeout=300s
```

### Step 6: Access Services

Open **three separate PowerShell/CMD terminals** and run:

```powershell
# Terminal 1 - Frontend
kubectl port-forward -n autocare360 svc/autocare360-frontend-service 3000:80

# Terminal 2 - Backend
kubectl port-forward -n autocare360 svc/autocare360-backend-service 8080:8080

# Terminal 3 - Chatbot
kubectl port-forward -n autocare360 svc/autocare360-chatbot-service 8000:8000
```

### Step 7: Access the Application

Visit in your browser:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Chatbot API**: http://localhost:8000
- **Backend Health**: http://localhost:8080/actuator/health
- **Chatbot Health**: http://localhost:8000/health

## 📋 Prerequisites

Before you begin, ensure you have:

- ✅ **Docker Desktop** with Kubernetes enabled
- ✅ **kubectl** installed and configured
- ✅ **Access to your application images** (or build them first)

### Windows Setup
1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Enable Kubernetes in Docker Desktop settings (Settings → Kubernetes → Enable Kubernetes)
3. kubectl is included with Docker Desktop
4. Verify installation:
   ```powershell
   kubectl version --client
   docker --version
   ```

### Linux/Mac Setup
1. Install Docker and kubectl
2. Enable Kubernetes in Docker Desktop or use Minikube
3. Verify installation:
   ```bash
   kubectl version --client
   docker --version
   ```

---

## 🏭 Production Deployment

### Step 1: Setup Production Environment Variables

```powershell
# Copy the environment template
copy .env.example .env.prod
```

**Edit `.env.prod`** with **STRONG PRODUCTION VALUES**:
- Use strong, unique passwords (min 16 characters)
- Generate a secure JWT secret (min 256 bits)
- Use production API keys
- Update `SPRING_PROFILES_ACTIVE=prod`
- Update `ENV=prod`
- Update URLs to production domains
- Update CORS origins to production domains
- **Never reuse dev credentials in production!**

### Step 2: Create Production Secrets

```powershell
# Create namespace (if not exists)
kubectl create namespace autocare360

# Create production secrets
kubectl create secret generic autocare360-secrets `
  --from-env-file=.env.prod `
  -n autocare360
```

### Step 3: Deploy to Production

```powershell
kubectl apply -k deployment\kubernetes\overlays\prod
```

### Step 4: Verify Production Deployment

```powershell
# Check all pods are running
kubectl get pods -n autocare360

# Check services
kubectl get svc -n autocare360

# View logs if needed
kubectl logs -f deployment/autocare360-backend -n autocare360
```

---

## 🔧 Common Operations

### Update Environment Variables

If you need to change environment variables after deployment:

```powershell
# Update the secret
kubectl create secret generic autocare360-secrets `
  --from-env-file=.env `
  -n autocare360 `
  --dry-run=client -o yaml | kubectl apply -f -

# Restart deployments to pick up changes
kubectl rollout restart deployment/autocare360-backend -n autocare360
kubectl rollout restart deployment/autocare360-frontend -n autocare360
kubectl rollout restart deployment/autocare360-chatbot -n autocare360
```

### View Logs

```powershell
# Backend logs
kubectl logs -f deployment/autocare360-backend -n autocare360

# Frontend logs
kubectl logs -f deployment/autocare360-frontend -n autocare360

# Chatbot logs
kubectl logs -f deployment/autocare360-chatbot -n autocare360

# MySQL logs
kubectl logs -f deployment/mysql -n autocare360
```

### Check Pod Status

```powershell
# Get all resources
kubectl get all -n autocare360

# Describe a specific pod
kubectl describe pod <pod-name> -n autocare360

# Get pod events
kubectl get events -n autocare360 --sort-by='.lastTimestamp'
```

### Restart Services

```powershell
# Restart a specific deployment
kubectl rollout restart deployment/autocare360-backend -n autocare360

# Check rollout status
kubectl rollout status deployment/autocare360-backend -n autocare360

# Restart all deployments
kubectl rollout restart deployment -n autocare360
```

### Scale Services

```powershell
# Scale backend to 3 replicas
kubectl scale deployment/autocare360-backend --replicas=3 -n autocare360

# Scale frontend to 2 replicas
kubectl scale deployment/autocare360-frontend --replicas=2 -n autocare360
```

### Clean Up Everything

```powershell
# Delete entire namespace (removes everything)
kubectl delete namespace autocare360

# Or delete specific resources
kubectl delete -k deployment\kubernetes\overlays\dev
```

---

## 📚 Available Commands

### Using Makefile (Optional - Requires Git Bash/WSL)

```bash
make help              # Show all commands
make check-prereqs     # Verify tools installed
make setup             # Complete setup (build + deploy)
make deploy            # Deploy to Kubernetes
make status            # Show deployment status
make logs POD=backend  # View logs
make port-forward      # Forward ports to localhost
make restart           # Restart all deployments
make clean             # Delete all resources
```

---

## 🐳 Building Docker Images (If Needed)

If you need to build the Docker images locally:

### Step 1: Build Backend Image

```powershell
cd ..\dev-autocare360-backend
docker build -t ghcr.io/colabdevelopers/dev-autocare360-backend:latest .
cd ..\autocare360-infrastructure
```

### Step 2: Build Frontend Image

```powershell
cd ..\dev-autocare360-frontend
docker build -t ghcr.io/colabdevelopers/dev-autocare360-frontend:latest .
cd ..\autocare360-infrastructure
```

### Step 3: Build Chatbot Image

```powershell
cd ..\autocare360-chatbot
docker build -t ghcr.io/colabdevelopers/autocare360-chatbot:latest .
cd ..\autocare360-infrastructure
```

### Step 4: Verify Images

```powershell
docker images | findstr autocare360
```

---

### Check Status
```powershell
kubectl get all -n autocare360
```

### Clean Up
```powershell
kubectl delete namespace autocare360
```

## Configuration

### Environment Variables

All configuration is centralized in the `.env.example` file. Copy it to `.env` and fill in your actual values.

The `.env` file contains variables for all three services:
- **Backend** (Spring Boot) - Database, JWT, CORS, Logging
- **Frontend** (Next.js) - API URLs, Feature Flags
- **Chatbot** (FastAPI) - AI Providers, Database, Redis

#### Quick Setup

**Development:**
```powershell
# Copy .env.example and edit with your values
copy .env.example .env

# Create secrets
kubectl create secret generic autocare360-secrets --from-env-file=.env -n autocare360
```

**Production:**
```powershell
# Copy .env.example and edit with PRODUCTION values
copy .env.example .env.prod
# Update SPRING_PROFILES_ACTIVE=prod, ENV=prod, and production URLs

# Create secrets
kubectl create secret generic autocare360-secrets --from-env-file=.env.prod -n autocare360
```

#### Key Variables

**Backend (Spring Boot):**
- Database: `DB_URL`, `MYSQL_USER`, `MYSQL_PASSWORD`
- Security: `JWT_SECRET` (minimum 256 bits)
- CORS: `CORS_ALLOWED_ORIGINS`

**Frontend (Next.js):**
- APIs: `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_CHATBOT_URL`
- Features: `NEXT_PUBLIC_ENABLE_CHATBOT`, `NEXT_PUBLIC_ENABLE_ANALYTICS`

**Chatbot (FastAPI):**
- AI: `AI_PROVIDER`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `GROK_API_KEY`
- Database: `MYSQL_HOST`, `MYSQL_USER`, `MYSQL_PASSWORD`
- Cache: `REDIS_URL`

---

## 🗂️ Directory Structure

```
autocare360-infrastructure/
├── deployment/
│   └── kubernetes/
│       ├── base/                          # Base Kubernetes manifests
│       │   ├── backend-deployment.yaml
│       │   ├── backend-service.yaml
│       │   ├── frontend-deployment.yaml
│       │   ├── frontend-service.yaml
│       │   ├── chatbot-deployment.yaml
│       │   ├── chatbot-service.yaml
│       │   ├── db-mysql-deployment.yaml
│       │   ├── db-mysql-service.yaml
│       │   ├── db-redis-deployment.yaml
│       │   ├── db-redis-service.yaml
│       │   ├── configmap.yaml             # Non-sensitive config
│       │   ├── secrets.yaml               # Secret placeholders
│       │   ├── namespace.yaml
│       │   ├── kustomization.yaml
│       │   ├── network/
│       │   │   └── ingress.yaml
│       │   ├── rbac/
│       │   │   ├── role.yaml
│       │   │   ├── rolebinding.yaml
│       │   │   └── serviceaccount.yaml
│       │   └── storage/
│       │       ├── mysql-pvc.yaml
│       │       └── redis-pvc.yaml
│       ├── overlays/
│       │   ├── dev/                       # Development overrides
│       │   │   ├── kustomization.yaml
│       │   │   ├── patch.yaml
│       │   │   ├── configmap-patch.yaml
│       │   │   └── .env.template          # Secret template
│       │   └── prod/                      # Production overrides
│       │       ├── kustomization.yaml
│       │       ├── patch.yaml
│       │       ├── configmap-patch.yaml
│       │       └── .env.template          # Secret template
│       └── ENV_VARIABLES.md               # Complete env var docs
├── Makefile                                # Linux/Mac commands
├── README.md                               # This file
├── .gitignore                              # Protects secrets
└── ENVIRONMENT_SETUP_SUMMARY.md            # Quick reference

```

---

## ❗ Troubleshooting

### Problem: Pods Not Starting

**Check pod status:**
```powershell
kubectl get pods -n autocare360
kubectl describe pod <pod-name> -n autocare360
```

**Common causes:**
- Secrets not created: Run Step 3 again
- Wrong secret values: Check your `.env` file
- Image pull errors: Build images locally (see Building Docker Images section)

### Problem: Connection Refused / Service Unavailable

**Check services:**
```powershell
kubectl get svc -n autocare360
```

**Verify port-forwards are running:**
- Make sure you have separate terminals running the port-forward commands
- Check that no other services are using ports 3000, 8080, or 8000

### Problem: Database Connection Errors

**Check MySQL pod:**
```powershell
kubectl logs -f deployment/mysql -n autocare360
```

**Verify secrets:**
```powershell
# Check if secret exists
kubectl get secret autocare360-secrets -n autocare360

# View secret keys (not values)
kubectl get secret autocare360-secrets -n autocare360 -o jsonpath="{.data}" | findstr "MYSQL"
```

### Problem: Backend Health Check Failing

**Check backend logs:**
```powershell
kubectl logs -f deployment/autocare360-backend -n autocare360
```

**Common issues:**
- Database not ready: Wait for MySQL pod to be Running
- Wrong DB credentials: Verify your `.env` file
- Wrong DB_URL: Should be `jdbc:mysql://mysql-service:3306/autocare360`

### Problem: Need to Start Fresh

**Clean everything and redeploy:**
```powershell
# Delete everything
kubectl delete namespace autocare360

# Wait a moment, then start over from Step 2
kubectl create namespace autocare360
# ... continue with steps
```

### Problem: Environment Variables Not Updating

**After changing `.env`:**
```powershell
# Recreate the secret
kubectl create secret generic autocare360-secrets `
  --from-env-file=.env `
  -n autocare360 `
  --dry-run=client -o yaml | kubectl apply -f -

# Restart all deployments
kubectl rollout restart deployment -n autocare360
```

### Getting Help

**View all resources:**
```powershell
kubectl get all -n autocare360
```

**View recent events:**
```powershell
kubectl get events -n autocare360 --sort-by='.lastTimestamp'
```

**Check resource usage:**
```powershell
kubectl top pods -n autocare360
```

---

## 📖 Additional Documentation

All environment variables are documented in `.env.example` with clear comments for each section.

---

## 🔐 Security Notes

⚠️ **Important Security Practices:**

1. **Never commit `.env.dev` or `.env.prod` files** - Only commit `.env.template` files
2. **Use strong passwords** in production (minimum 16 characters, mixed case, numbers, symbols)
3. **Generate secure JWT secrets** (minimum 256 bits, use a generator)
4. **Rotate secrets regularly** - Especially in production
5. **Use different credentials** for dev and prod environments
6. **Consider using external secret managers** for production:
   - Kubernetes External Secrets Operator
   - HashiCorp Vault
   - Cloud provider secret managers (AWS Secrets Manager, Azure Key Vault, etc.)

---

## 🎯 Architecture Overview

The AutoCare360 application consists of:

- **Frontend** (Next.js) - Port 3000
- **Backend** (Spring Boot) - Port 8080
- **Chatbot** (FastAPI/Python) - Port 8000
- **MySQL Database** - Port 3306 (internal)
- **Redis Cache** - Port 6379 (internal)

### Service Communication

```
Frontend → Backend API → MySQL Database
Frontend → Chatbot API → MySQL Database
                      → Redis Cache
```

### Environment Variables Flow

```
.env.template (safe to commit)
      ↓
.env.dev/.env.prod (NEVER commit)
      ↓
Kubernetes Secret (base64 encoded)
      ↓
Pod Environment Variables
      ↓
Application Configuration
```

---

## 💡 Tips & Best Practices

### Development
- Use debug logging to troubleshoot issues
- Keep dev credentials simple but secure
- Use `kubectl logs -f` to watch logs in real-time
- Test one service at a time when debugging

### Production
- Always use strong, unique credentials
- Enable production-level logging (INFO/WARN)
- Use multiple replicas for high availability
- Set up monitoring and alerting
- Regular backups of MySQL data
- Use Ingress for external access (not port-forward)

### Kustomize
- Base contains common configuration
- Overlays contain environment-specific patches
- Dev overlay: debug settings, single replicas
- Prod overlay: optimized settings, multiple replicas

---

## 📝 License

This infrastructure configuration is part of the AutoCare360 project.

---

## 🤝 Contributing

When contributing to this infrastructure:

1. Never commit actual secrets or credentials
2. Test changes in dev environment first
3. Update documentation when adding new environment variables
4. Follow the existing structure and naming conventions
5. Use meaningful commit messages

---

**For detailed setup instructions and troubleshooting, refer to the step-by-step guide above.**

