# GitHub Secrets Setup Guide

This guide explains how to configure GitHub secrets for the AutoCare360 application deployment.

## Required GitHub Secrets

Add the following secrets to your GitHub repository settings under "Secrets and variables" > "Actions":

### Database Secrets
- `MYSQL_ROOT_PASSWORD`: MySQL root password
- `MYSQL_DATABASE`: Database name (e.g., `autocare360`)
- `MYSQL_USER`: MySQL application user
- `MYSQL_PASSWORD`: MySQL application user password

### Application Secrets
- `JWT_SECRET`: JWT signing secret (minimum 256 bits)
- `OPENAI_API_KEY`: OpenAI API key for chatbot functionality
- `DB_URL`: JDBC database URL (e.g., `jdbc:mysql://mysql-service:3306/autocare360`)

### CI/CD Infrastructure Secrets
- `KUBE_CONFIG_DEV`: Base64 encoded kubeconfig for development cluster
- `KUBE_CONFIG_PROD`: Base64 encoded kubeconfig for production cluster

## How to Encode Secrets

For secrets that need to be base64 encoded (like `DB_URL`), use:

```bash
echo -n "your_secret_value" | base64
```

## Example Values

```bash
# JWT Secret (generate a secure random string)
JWT_SECRET=$(openssl rand -base64 32)

# Database URL
DB_URL=$(echo -n "jdbc:mysql://mysql-service:3306/autocare360" | base64)

# MySQL Credentials
MYSQL_ROOT_PASSWORD=$(echo -n "your_secure_root_password" | base64)
MYSQL_USER=$(echo -n "autocare_user" | base64)
MYSQL_PASSWORD=$(echo -n "your_secure_app_password" | base64)
MYSQL_DATABASE=$(echo -n "autocare360" | base64)

# Kubernetes Config (if using external cluster)
KUBE_CONFIG_DEV=$(cat ~/.kube/config | base64 -w 0)
KUBE_CONFIG_PROD=$(cat ~/.kube/config | base64 -w 0)
```

## GitHub Actions Integration

The CI/CD pipeline automatically:
1. Builds Docker images for all components (backend, frontend, chatbot)
2. Pushes images to GitHub Container Registry
3. Creates Kubernetes secrets from GitHub secrets
4. Deploys to the appropriate environment (dev/prod)

The pipeline uses the following workflow:
- **Validate**: Checks Kubernetes manifests and Makefile syntax
- **Deploy-dev**: Builds and deploys to development on pushes to `dev` branch
- **Deploy-prod**: Builds and deploys to production on pushes to `main` branch

## Local Development

For local development, copy the `.env.example` files to `.env` and fill in your local values:

```bash
# Backend
cp dev-autocare360-backend/.env.example dev-autocare360-backend/.env

# Frontend
cp dev-autocare360-frontend/.env.example dev-autocare360-frontend/.env

# Chatbot
cp autocare360-chatbot/.env.example autocare360-chatbot/.env
```