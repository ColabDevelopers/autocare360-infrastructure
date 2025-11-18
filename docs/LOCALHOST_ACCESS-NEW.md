# AutoCare360 Localhost Access Guide

## 🎉 Problem Fixed! Kubernetes Network Issue Resolved

The Kubernetes cluster network problem has been **successfully fixed**. You can now access all services via localhost using standard ports with port-forwarding.

## 🚀 Service Access URLs (Standard Ports)

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Frontend** | http://localhost:3000 | 3000 | Main web application |
| **Backend API** | http://localhost:8080 | 8080 | REST API endpoints |
| **Chatbot API** | http://localhost:8001 | 8001 | AI Chatbot service (port 8000 was in use) |

## 🏥 Health Check Endpoints

- **Backend Health**: http://localhost:8080/actuator/health
- **Chatbot Health**: http://localhost:8001/health
- **Backend Info**: http://localhost:8080/actuator/info

## 📋 Project Status

✅ **All services are running and accessible via port-forwarding!**

```powershell
PS> kubectl get pods -n autocare360
NAME                                    READY   STATUS    RESTARTS
autocare360-backend-67f5dc5649-vh64b    1/1     Running   1
autocare360-chatbot-75f647dd8b-77rm9    1/1     Running   1  
autocare360-frontend-5bb44f6b8b-2g798   1/1     Running   0
mysql-bd7f4d5dd-vxhfr                   1/1     Running   1
redis-6c57f5c96c-qvrbj                  1/1     Running   1
```

## 🛠 Current Configuration

### 1. Service Type: ClusterIP
- All services use ClusterIP (internal cluster access only)
- Access via port-forwarding to localhost with standard ports
- More secure than NodePort, follows Kubernetes best practices

### 2. Port Forwarding Active
- **Frontend**: `kubectl port-forward -n autocare360 svc/autocare360-frontend-service 3000:3000`
- **Backend**: `kubectl port-forward -n autocare360 svc/autocare360-backend-service 8080:8080`  
- **Chatbot**: `kubectl port-forward -n autocare360 svc/autocare360-chatbot-service 8001:8000`

### 3. Environment Configuration
- Frontend configured to use: http://localhost:8080 (backend) and http://localhost:8000 (chatbot)
- CORS allows localhost origins on standard ports
- Development environment with proper JWT secrets and database credentials

## 🚀 Quick Start Commands

### Start Port Forwarding
```bash
# Frontend (port 3000)
kubectl port-forward -n autocare360 svc/autocare360-frontend-service 3000:3000

# Backend (port 8080) - in new terminal
kubectl port-forward -n autocare360 svc/autocare360-backend-service 8080:8080

# Chatbot (port 8001) - in new terminal
kubectl port-forward -n autocare360 svc/autocare360-chatbot-service 8001:8000
```

### Access the Application
- **Main App**: Open http://localhost:3000 in your browser
- **API Health**: Check http://localhost:8080/actuator/health
- **Chatbot**: Access via http://localhost:8001/health

### Check Status
```bash
# Check pod status
kubectl get pods -n autocare360

# View logs
kubectl logs -n autocare360 deployment/autocare360-frontend
kubectl logs -n autocare360 deployment/autocare360-backend
kubectl logs -n autocare360 deployment/autocare360-chatbot
```

## 🔧 Troubleshooting

### If Port Forwarding Stops Working
1. Check if the terminals are still running
2. Restart port-forwarding commands
3. Verify pods are running: `kubectl get pods -n autocare360`

### If Ports Are In Use
- Use alternative ports like 3001, 8081, 8001
- Check what's using ports: `netstat -an | findstr :3000`
- Kill processes using the ports if needed

### Alternative Access (If Port Forwarding Fails)
```bash
# Use different local ports
kubectl port-forward -n autocare360 svc/autocare360-frontend-service 3001:3000
kubectl port-forward -n autocare360 svc/autocare360-backend-service 8081:8080
```

## 📝 Notes

- **Port 8000 was already in use**, so chatbot is available on port 8001
- Port-forwarding requires keeping terminal sessions open
- Services use ClusterIP type for better security
- All data persists in PersistentVolumes (MySQL data won't be lost)

## 🎯 Current Access Summary

**✅ WORKING NOW:**
- Frontend: http://localhost:3000 (port-forwarded)
- Backend: http://localhost:8080 (port-forwarded)  
- Chatbot: http://localhost:8001 (port-forwarded to avoid port conflict)

**🎉 Your AutoCare360 application is now running on standard ports 3000, 8080, 8000 (8001)!**