# AutoCare360 DevOps Guide

This comprehensive guide provides DevOps engineers with detailed instructions for deploying, managing, and maintaining the AutoCare360 system in various environments.

## 📋 Table of Contents

- [System Architecture](#-system-architecture)
- [Infrastructure Overview](#-infrastructure-overview)
- [Environment Setup](#-environment-setup)
- [Deployment Strategies](#-deployment-strategies)
- [Monitoring and Logging](#-monitoring-and-logging)
- [Security Configuration](#-security-configuration)
- [Scaling and Performance](#-scaling-and-performance)
- [Backup and Disaster Recovery](#-backup-and-disaster-recovery)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Troubleshooting Guide](#-troubleshooting-guide)
- [Maintenance Procedures](#-maintenance-procedures)

## 🏗️ System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          Load Balancer                          │
│                      (NGINX/AWS ALB)                           │
└─────────────────┬───────────────────────────────────────────────┘
                  │
    ┌─────────────┴─────────────┐
    │         Ingress           │
    │    (NGINX Controller)     │
    └─────────────┬─────────────┘
                  │
┌─────────────────┼─────────────────┐
│        Kubernetes Cluster        │
│                                   │
│  ┌─────────────┐ ┌─────────────┐ │  ┌─────────────────┐
│  │  Frontend   │ │   Backend   │ │  │    Chatbot      │
│  │  (Next.js)  │ │ (Spring Boot│ │  │   (FastAPI)     │
│  │   Pods      │ │    Pods     │ │  │     Pods        │
│  └─────────────┘ └─────────────┘ │  └─────────────────┘
│         │               │        │           │
│         └───────────────┼────────┼───────────┘
│                         │        │
│  ┌─────────────────────────────────────────────────────┐
│  │               Persistent Storage                     │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│  │  │    MySQL    │  │    Redis    │  │   File      │ │
│  │  │   Database  │  │    Cache    │  │  Storage    │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘ │
│  └─────────────────────────────────────────────────────┘
└───────────────────────────────────────────────────────────────┘
```

### Service Dependencies

```mermaid
graph TD
    A[Frontend] --> B[Backend API]
    A --> C[Chatbot API]
    B --> D[MySQL Database]
    B --> E[Redis Cache]
    C --> D
    C --> F[AI Provider APIs]
    B --> G[File Storage]
```

## 🔧 Infrastructure Overview

### Technology Stack

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| **Container Orchestration** | Kubernetes | 1.25+ | Container management |
| **Container Runtime** | Docker | 20.10+ | Containerization |
| **Frontend** | Next.js | 14.x | Web application |
| **Backend** | Spring Boot | 3.5.x | REST API service |
| **Chatbot** | FastAPI | 0.104+ | AI chatbot service |
| **Database** | MySQL | 8.0 | Primary database |
| **Cache** | Redis | 7.0 | Caching layer |
| **Reverse Proxy** | NGINX | 1.24+ | Load balancing |
| **Monitoring** | Prometheus/Grafana | Latest | Metrics & dashboards |
| **Logging** | ELK Stack | 8.x | Log aggregation |

### Resource Requirements

#### Minimum Requirements (Development)

| Service | CPU | Memory | Storage |
|---------|-----|--------|---------|
| Frontend | 100m | 256Mi | 1Gi |
| Backend | 500m | 512Mi | 2Gi |
| Chatbot | 200m | 512Mi | 1Gi |
| MySQL | 500m | 1Gi | 10Gi |
| Redis | 100m | 128Mi | 1Gi |

#### Production Requirements

| Service | CPU | Memory | Storage | Replicas |
|---------|-----|--------|---------|----------|
| Frontend | 200m | 512Mi | 2Gi | 2-5 |
| Backend | 1000m | 1Gi | 5Gi | 2-10 |
| Chatbot | 500m | 1Gi | 2Gi | 2-5 |
| MySQL | 2000m | 4Gi | 100Gi | 1 (HA setup) |
| Redis | 500m | 1Gi | 10Gi | 1-3 |

## ⚙️ Environment Setup

### Prerequisites

1. **Kubernetes Cluster**:
   - Kubernetes 1.25+
   - kubectl configured
   - Cluster admin access

2. **Container Registry**:
   - Docker Hub, AWS ECR, or Azure ACR
   - Push/pull access

3. **Monitoring Stack** (optional):
   - Prometheus
   - Grafana
   - AlertManager

### Environment Configuration

#### 1. Development Environment

```bash
# Clone infrastructure repository
git clone https://github.com/ColabDevelopers/autocare360-infrastructure.git
cd autocare360-infrastructure

# Create development environment file
cp .env.example .env.dev

# Edit development configuration
cat > .env.dev << EOF
# Environment
ENV=development
SPRING_PROFILES_ACTIVE=dev

# Database Configuration
MYSQL_ROOT_PASSWORD=dev_root_password_123
MYSQL_DATABASE=autocare360_dev
MYSQL_USER=autocare360_dev_user
MYSQL_PASSWORD=dev_password_123
MYSQL_HOST=mysql-service
MYSQL_PORT=3306

# Application Configuration
JWT_SECRET=dev-jwt-secret-key-256-bits-minimum
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000

# AI Configuration (choose one)
OPENAI_API_KEY=your-dev-openai-key
# GOOGLE_API_KEY=your-dev-gemini-key
# GROK_API_KEY=your-dev-grok-key

# Redis Configuration
REDIS_HOST=redis-service
REDIS_PORT=6379
REDIS_PASSWORD=dev_redis_password

# Application URLs
FRONTEND_URL=http://localhost:3000
BACKEND_URL=http://localhost:8080
CHATBOT_URL=http://localhost:8000
EOF

# Deploy to development
kubectl create namespace autocare360-dev
kubectl create secret generic autocare360-secrets \
  --from-env-file=.env.dev \
  -n autocare360-dev

kubectl apply -k deployment/kubernetes/overlays/dev/ -n autocare360-dev
```

#### 2. Staging Environment

```bash
# Create staging environment file
cat > .env.staging << EOF
# Environment
ENV=staging
SPRING_PROFILES_ACTIVE=staging

# Database Configuration
MYSQL_ROOT_PASSWORD=staging_root_password_secure_123
MYSQL_DATABASE=autocare360_staging
MYSQL_USER=autocare360_staging_user
MYSQL_PASSWORD=staging_password_secure_123
MYSQL_HOST=mysql-service
MYSQL_PORT=3306

# Application Configuration
JWT_SECRET=staging-jwt-secret-key-256-bits-very-secure
CORS_ALLOWED_ORIGINS=https://staging.autocare360.com,https://staging-api.autocare360.com

# AI Configuration
OPENAI_API_KEY=your-staging-openai-key

# Redis Configuration
REDIS_HOST=redis-service
REDIS_PORT=6379
REDIS_PASSWORD=staging_redis_secure_password

# Application URLs
FRONTEND_URL=https://staging.autocare360.com
BACKEND_URL=https://staging-api.autocare360.com
CHATBOT_URL=https://staging-chatbot.autocare360.com

# SSL Configuration
SSL_ENABLED=true
EOF

# Deploy to staging
kubectl create namespace autocare360-staging
kubectl create secret generic autocare360-secrets \
  --from-env-file=.env.staging \
  -n autocare360-staging

# Apply staging-specific configurations
kubectl apply -k deployment/kubernetes/overlays/staging/ -n autocare360-staging
```

#### 3. Production Environment

```bash
# Create production environment file
cat > .env.prod << EOF
# Environment
ENV=production
SPRING_PROFILES_ACTIVE=prod

# Database Configuration (Use external managed database in production)
MYSQL_HOST=autocare360-prod.cluster-xyz.region.rds.amazonaws.com
MYSQL_PORT=3306
MYSQL_DATABASE=autocare360_prod
MYSQL_USER=autocare360_prod_user
MYSQL_PASSWORD=super_secure_production_password_2024

# Application Configuration
JWT_SECRET=production-jwt-secret-key-512-bits-extremely-secure-2024
CORS_ALLOWED_ORIGINS=https://autocare360.com,https://api.autocare360.com

# AI Configuration
OPENAI_API_KEY=your-production-openai-key

# Redis Configuration (Use external managed Redis in production)
REDIS_HOST=autocare360-prod.cache.amazonaws.com
REDIS_PORT=6379
REDIS_PASSWORD=super_secure_redis_production_password

# Application URLs
FRONTEND_URL=https://autocare360.com
BACKEND_URL=https://api.autocare360.com
CHATBOT_URL=https://chatbot.autocare360.com

# SSL Configuration
SSL_ENABLED=true
FORCE_HTTPS=true

# Performance Configuration
MAX_CONNECTIONS=500
CONNECTION_TIMEOUT=30000
READ_TIMEOUT=60000

# Logging
LOG_LEVEL=INFO
LOG_FORMAT=json
EOF

# Deploy to production
kubectl create namespace autocare360-prod
kubectl create secret generic autocare360-secrets \
  --from-env-file=.env.prod \
  -n autocare360-prod

kubectl apply -k deployment/kubernetes/overlays/prod/ -n autocare360-prod
```

## 🚀 Deployment Strategies

### 1. Blue-Green Deployment

```bash
# Deploy to green environment
kubectl apply -k deployment/kubernetes/overlays/prod-green/ -n autocare360-prod

# Test green environment
kubectl port-forward svc/autocare360-frontend-green 8080:80 -n autocare360-prod
# Perform testing...

# Switch traffic to green
kubectl patch service autocare360-frontend-service \
  -n autocare360-prod \
  -p '{"spec":{"selector":{"version":"green"}}}'

# Clean up blue environment after verification
kubectl delete -k deployment/kubernetes/overlays/prod-blue/ -n autocare360-prod
```

### 2. Rolling Update

```bash
# Update image version
kubectl set image deployment/autocare360-backend \
  backend=autocare360/backend:v1.2.0 \
  -n autocare360-prod

# Monitor rollout
kubectl rollout status deployment/autocare360-backend -n autocare360-prod

# Rollback if needed
kubectl rollout undo deployment/autocare360-backend -n autocare360-prod
```

### 3. Canary Deployment

```yaml
# deployment/kubernetes/overlays/prod/canary-deployment.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: autocare360-backend-canary
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: {duration: 10m}
      - setWeight: 20
      - pause: {duration: 10m}
      - setWeight: 50
      - pause: {duration: 10m}
  selector:
    matchLabels:
      app: autocare360-backend
  template:
    # ... pod template
```

## 📊 Monitoring and Logging

### 1. Prometheus Setup

```yaml
# monitoring/prometheus-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
    - job_name: 'autocare360-backend'
      static_configs:
      - targets: ['autocare360-backend-service:8080']
      metrics_path: '/actuator/prometheus'
    - job_name: 'autocare360-chatbot'
      static_configs:
      - targets: ['autocare360-chatbot-service:8000']
      metrics_path: '/metrics'
```

### 2. Grafana Dashboards

```bash
# Install Grafana
kubectl apply -f monitoring/grafana-deployment.yaml

# Import dashboard
curl -X POST \
  http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @monitoring/autocare360-dashboard.json
```

### 3. Log Aggregation

```yaml
# logging/fluentd-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      format json
    </source>
    
    <match kubernetes.**>
      @type elasticsearch
      host elasticsearch
      port 9200
      index_name autocare360
    </match>
```

### 4. Health Checks

```yaml
# Kubernetes health checks
livenessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 30

readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
```

## 🔐 Security Configuration

### 1. RBAC Setup

```yaml
# security/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: autocare360-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: autocare360-rolebinding
subjects:
- kind: ServiceAccount
  name: autocare360-serviceaccount
roleRef:
  kind: Role
  name: autocare360-role
  apiGroup: rbac.authorization.k8s.io
```

### 2. Network Policies

```yaml
# security/network-policies.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: autocare360-network-policy
spec:
  podSelector:
    matchLabels:
      app: autocare360
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: autocare360-prod
    ports:
    - protocol: TCP
      port: 8080
```

### 3. Pod Security Standards

```yaml
# security/pod-security-policy.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: autocare360-psp
spec:
  privileged: false
  runAsUser:
    rule: MustRunAsNonRoot
  seLinux:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  volumes:
  - configMap
  - emptyDir
  - projected
  - secret
  - downwardAPI
  - persistentVolumeClaim
```

### 4. Secret Management

```bash
# Using sealed-secrets
kubectl create secret generic autocare360-secrets \
  --from-env-file=.env.prod \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > sealed-secrets.yaml

kubectl apply -f sealed-secrets.yaml
```

## 📈 Scaling and Performance

### 1. Horizontal Pod Autoscaling

```yaml
# scaling/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: autocare360-backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: autocare360-backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### 2. Vertical Pod Autoscaling

```yaml
# scaling/vpa.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: autocare360-backend-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: autocare360-backend
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: backend
      maxAllowed:
        cpu: 2
        memory: 4Gi
      minAllowed:
        cpu: 100m
        memory: 256Mi
```

### 3. Performance Tuning

```yaml
# JVM tuning for backend
env:
- name: JAVA_OPTS
  value: "-Xmx1g -Xms512m -XX:+UseG1GC -XX:+UseContainerSupport"

# Database connection pool tuning
- name: SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE
  value: "20"
- name: SPRING_DATASOURCE_HIKARI_MINIMUM_IDLE
  value: "5"
- name: SPRING_DATASOURCE_HIKARI_CONNECTION_TIMEOUT
  value: "30000"
```

## 💾 Backup and Disaster Recovery

### 1. Database Backup

```bash
# Create backup job
kubectl create job mysql-backup-$(date +%Y%m%d) \
  --from=cronjob/mysql-backup \
  -n autocare360-prod

# Manual backup
kubectl exec -it mysql-0 -n autocare360-prod -- \
  mysqldump -u root -p autocare360_prod > backup-$(date +%Y%m%d).sql
```

### 2. Persistent Volume Backup

```yaml
# backup/velero-backup.yaml
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: autocare360-backup
spec:
  includedNamespaces:
  - autocare360-prod
  storageLocation: default
  volumeSnapshotLocations:
  - default
  ttl: 720h0m0s
```

### 3. Disaster Recovery Plan

```bash
# Restore from backup
velero restore create --from-backup autocare360-backup

# Verify restoration
kubectl get pods -n autocare360-prod
kubectl get pvc -n autocare360-prod
```

## 🔄 CI/CD Pipeline

### 1. GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy AutoCare360
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Run tests
      run: |
        # Run frontend tests
        cd dev-autocare360-frontend && npm test
        # Run backend tests
        cd dev-autocare360-backend && mvn test
        # Run chatbot tests
        cd autocare360-chatbot && pytest

  build-and-deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v3
    - name: Build and push images
      run: |
        docker build -t autocare360/frontend:${{ github.sha }} ./dev-autocare360-frontend
        docker build -t autocare360/backend:${{ github.sha }} ./dev-autocare360-backend
        docker build -t autocare360/chatbot:${{ github.sha }} ./autocare360-chatbot
        docker push autocare360/frontend:${{ github.sha }}
        docker push autocare360/backend:${{ github.sha }}
        docker push autocare360/chatbot:${{ github.sha }}
    
    - name: Deploy to Kubernetes
      run: |
        kubectl set image deployment/autocare360-frontend frontend=autocare360/frontend:${{ github.sha }} -n autocare360-prod
        kubectl set image deployment/autocare360-backend backend=autocare360/backend:${{ github.sha }} -n autocare360-prod
        kubectl set image deployment/autocare360-chatbot chatbot=autocare360/chatbot:${{ github.sha }} -n autocare360-prod
```

### 2. GitOps with ArgoCD

```yaml
# gitops/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: autocare360
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/ColabDevelopers/autocare360-infrastructure
    targetRevision: HEAD
    path: deployment/kubernetes/overlays/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: autocare360-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

#### 1. Pod CrashLoopBackOff

```bash
# Check pod logs
kubectl logs <pod-name> -n autocare360-prod --previous

# Check pod events
kubectl describe pod <pod-name> -n autocare360-prod

# Common fixes:
# - Check resource limits
# - Verify environment variables
# - Check image availability
# - Verify dependencies (database, Redis)
```

#### 2. Service Connectivity Issues

```bash
# Test service connectivity
kubectl exec -it <test-pod> -n autocare360-prod -- curl http://service-name:port

# Check service endpoints
kubectl get endpoints -n autocare360-prod

# Verify service selector
kubectl describe service <service-name> -n autocare360-prod
```

#### 3. Database Connection Problems

```bash
# Check MySQL pod
kubectl logs mysql-0 -n autocare360-prod

# Test database connection
kubectl exec -it mysql-0 -n autocare360-prod -- mysql -u root -p

# Verify secrets
kubectl get secret autocare360-secrets -o yaml -n autocare360-prod
```

#### 4. Performance Issues

```bash
# Check resource usage
kubectl top pods -n autocare360-prod
kubectl top nodes

# Check HPA status
kubectl get hpa -n autocare360-prod

# Analyze metrics
kubectl port-forward svc/prometheus 9090:9090
```

### Emergency Procedures

#### 1. Scale Down Services

```bash
# Emergency scale down
kubectl scale deployment autocare360-frontend --replicas=0 -n autocare360-prod
kubectl scale deployment autocare360-backend --replicas=1 -n autocare360-prod
kubectl scale deployment autocare360-chatbot --replicas=0 -n autocare360-prod
```

#### 2. Database Recovery

```bash
# Stop all services
kubectl scale deployment --all --replicas=0 -n autocare360-prod

# Restore database
kubectl exec -it mysql-0 -n autocare360-prod -- mysql -u root -p < latest-backup.sql

# Restart services
kubectl scale deployment autocare360-backend --replicas=2 -n autocare360-prod
```

## 🔄 Maintenance Procedures

### Regular Maintenance Tasks

#### Daily

- [ ] Check cluster health
- [ ] Review monitoring alerts
- [ ] Verify backup completion
- [ ] Check resource utilization

```bash
# Daily health check script
kubectl get nodes
kubectl get pods --all-namespaces
kubectl top nodes
kubectl top pods -n autocare360-prod
```

#### Weekly

- [ ] Update security patches
- [ ] Review performance metrics
- [ ] Clean up unused resources
- [ ] Test disaster recovery procedures

```bash
# Weekly cleanup script
kubectl delete pods --field-selector=status.phase=Succeeded -n autocare360-prod
docker system prune -f
```

#### Monthly

- [ ] Update base images
- [ ] Review capacity planning
- [ ] Update documentation
- [ ] Security audit
- [ ] Performance optimization review

### Upgrade Procedures

#### 1. Kubernetes Cluster Upgrade

```bash
# Drain nodes one by one
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Upgrade node
# (Platform-specific upgrade commands)

# Uncordon node
kubectl uncordon <node-name>
```

#### 2. Application Updates

```bash
# Update to new version
kubectl set image deployment/autocare360-backend \
  backend=autocare360/backend:v2.0.0 \
  -n autocare360-prod

# Monitor rollout
kubectl rollout status deployment/autocare360-backend -n autocare360-prod

# Verify deployment
kubectl get pods -l app=autocare360-backend -n autocare360-prod
```

## 📚 Additional Resources

### Documentation Links

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Spring Boot Operations](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)
- [Next.js Deployment](https://nextjs.org/docs/deployment)

### Monitoring and Alerting

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [ELK Stack Documentation](https://www.elastic.co/guide/)

### Security Best Practices

- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Container Security](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

## 🆘 Emergency Contacts

| Role | Contact | Availability |
|------|---------|--------------|
| Lead DevOps Engineer | devops-lead@company.com | 24/7 |
| Platform Team | platform-team@company.com | Business hours |
| Security Team | security@company.com | 24/7 |
| Database Admin | dba@company.com | Business hours |

---

**Remember**: Always test procedures in staging before applying to production! 🚀