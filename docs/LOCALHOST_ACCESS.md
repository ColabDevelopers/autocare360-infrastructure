# AutoCare360 Localhost Access Guide

## 🎉 Problem Fixed! Kubernetes Network Issue Resolved

The Kubernetes cluster network problem has been **successfully fixed**. You can now access all services via localhost using NodePort services.

## 🚀 Service Access URLs

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Frontend** | http://localhost:30300 | 30300 | Main web application |
| **Backend API** | http://localhost:30800 | 30800 | REST API endpoints |
| **Chatbot API** | http://localhost:30080 | 30080 | AI Chatbot service |

## 🏥 Health Check Endpoints

- **Backend Health**: http://localhost:30800/actuator/health
- **Chatbot Health**: http://localhost:30080/health
- **Backend Info**: http://localhost:30800/actuator/info

## 📋 Project Status

✅ **All services are running and accessible!**

```powershell
PS> kubectl get pods -n autocare360
NAME                                    READY   STATUS    RESTARTS
autocare360-backend-67f5dc5649-vh64b    1/1     Running   1
autocare360-chatbot-75f647dd8b-77rm9    1/1     Running   1  
autocare360-frontend-5bb44f6b8b-2g798   1/1     Running   0
mysql-bd7f4d5dd-vxhfr                   1/1     Running   1
redis-6c57f5c96c-qvrbj                  1/1     Running   1
```

## 🛠 What Was Fixed

### 1. Service Type Changed to NodePort
- Changed all services from `ClusterIP` to `NodePort`
- Assigned specific NodePort numbers for consistent access
- Updated CORS configuration to allow NodePort origins

### 2. Network Configuration Updates
- **Frontend Service**: Port 3000 → NodePort 30300
- **Backend Service**: Port 8080 → NodePort 30800  
- **Chatbot Service**: Port 8000 → NodePort 30080

### 3. Environment Configuration
- Updated `.env` file with proper development values
- Configured CORS to allow localhost NodePort access
- Set proper JWT secrets and database credentials

### 4. Ingress Configuration
- Added localhost support to ingress
- Configured both `localhost` and `autocare360.local` hosts
- Added proper annotations for NGINX ingress

## 🚀 Quick Start Commands

### Deploy and Access
```bash
# Deploy the application
make deploy

# Check status
kubectl get pods -n autocare360

# Show NodePort URLs
make nodeport-access

# Open frontend in browser
start http://localhost:30300
```

### Port Forwarding (Alternative Access)
```bash
# Set up port forwarding (alternative method)
make port-forward

# This will forward:
# - Frontend: http://localhost:3000
# - Backend: http://localhost:8080  
# - Chatbot: http://localhost:8000
```

### Monitoring and Debugging
```bash
# View logs
kubectl logs -n autocare360 deployment/autocare360-frontend
kubectl logs -n autocare360 deployment/autocare360-backend
kubectl logs -n autocare360 deployment/autocare360-chatbot

# Shell access
kubectl exec -it -n autocare360 deployment/autocare360-backend -- /bin/bash

# Restart services
kubectl rollout restart -n autocare360 deployment/autocare360-frontend
kubectl rollout restart -n autocare360 deployment/autocare360-backend
```

## 🔧 Troubleshooting

### If Services Not Accessible
1. Check pod status: `kubectl get pods -n autocare360`
2. Check service ports: `kubectl get svc -n autocare360`
3. View logs: `kubectl logs -n autocare360 <pod-name>`
4. Restart deployment: `kubectl rollout restart -n autocare360 deployment/<service-name>`

### If Still Having Network Issues
```bash
# Alternative: Use port-forwarding
kubectl port-forward -n autocare360 svc/autocare360-frontend-service 3000:3000
kubectl port-forward -n autocare360 svc/autocare360-backend-service 8080:8080
kubectl port-forward -n autocare360 svc/autocare360-chatbot-service 8000:8000
```

### For Minikube Users
```bash
# Get minikube service URLs
minikube service list -n autocare360

# Open services in browser
minikube service autocare360-frontend-service -n autocare360
```

## 🎯 Next Steps

1. **Access the application**: Open http://localhost:30300 in your browser
2. **Test API endpoints**: Try http://localhost:30800/actuator/health
3. **Monitor logs**: Use `kubectl logs` commands to monitor application health
4. **Development**: Make changes to your code and redeploy using `make deploy`

## 📝 Notes

- All services use NodePort for localhost access
- Database (MySQL, Redis) services remain as ClusterIP (internal only)
- Environment is configured for development with debug logging
- CORS is configured to allow cross-origin requests from NodePort URLs

**🎉 Your AutoCare360 application is now running and accessible via localhost!**