Makefile Usage Guide

## ✅ **Successfully Created Windows-Compatible Makefile!**

Your AutoCare360 infrastructure now includes a comprehensive Makefile that works on Windows. Here's how to use it:

## 🚀 **Quick Start**

```cmd
# 1. Setup environment (copies .env.example to .env)
make setup-env

# 2. Edit .env file with your actual values
# (Update passwords, JWT secret, API keys, etc.)

# 3. Quick deployment (setup + deploy + wait for ready)
make quick-deploy
```

## 📋 **Main Commands**

### **Deployment**
- `make deploy` - Deploy to dev environment
- `make deploy ENV=prod` - Deploy to production
- `make quick-deploy` - Complete setup and deployment workflow

### **Monitoring**
- `make status` - Check all resources status
- `make logs` - View recent logs from all services
- `make wait-ready` - Wait for all pods to be ready

### **Port Forwarding** (Access services locally)
```cmd
# Individual services
kubectl port-forward -n autocare360 svc/autocare360-frontend-service 3000:3000
kubectl port-forward -n autocare360 svc/autocare360-backend-service 8080:8080
kubectl port-forward -n autocare360 svc/autocare360-chatbot-service 8000:8000
```

### **Management**
- `make restart` - Restart all deployments
- `make update-secrets` - Update secrets and restart
- `make clean-deployments` - Delete deployments only
- `make clean` - Delete everything (with confirmation)

### **Debugging**
- `make logs-backend` - Follow backend logs
- `make logs-frontend` - Follow frontend logs
- `make describe` - Describe all resources
- `make events` - Show recent events

## 🌐 **Access URLs** (after port forwarding)

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Backend Health**: http://localhost:8080/actuator/health
- **Chatbot API**: http://localhost:8000
- **Chatbot Health**: http://localhost:8000/health

## 🎯 **Current Status**

✅ **All services are running successfully!**
- MySQL: Running
- Redis: Running  
- Backend: Running
- Frontend: Running
- Chatbot: Running

## 💡 **Common Workflows**

### **Development Reset**
```cmd
make dev-reset    # Deletes and redeploys everything
```

### **Update Environment Variables**
```cmd
# 1. Edit .env file
# 2. Run:
make update-secrets
```

### **Production Deployment**
```cmd
# 1. Copy and edit production env
copy .env.example .env.prod
# 2. Edit .env.prod with production values
# 3. Deploy:
make prod-deploy ENV=prod
```

The Makefile has been successfully adapted for Windows and all your services are running! 🎉