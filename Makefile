# AutoCare360 Infrastructure Makefile
# Provides convenient commands for managing Kubernetes deployment

# Variables
NAMESPACE = autocare360
ENV ?= dev
KUBECTL = kubectl
KUSTOMIZE_PATH = deployment/kubernetes/overlays/$(ENV)

.PHONY: help setup-env create-namespace create-secrets deploy status logs clean port-forward restart update-secrets validate lint check-prerequisites

# Default target
help: ## Show this help message
	@echo AutoCare360 Infrastructure Management
	@echo =====================================
	@echo.
	@echo Available commands:
	@echo.
	@findstr /R /C:"^[a-zA-Z_-][a-zA-Z_-]*:.*##" $(MAKEFILE_LIST) | findstr /V /C:"@findstr"
	@echo.
	@echo Environment Variables:
	@echo   ENV=dev^|prod          Target environment (default: dev)
	@echo.
	@echo Examples:
	@echo   make deploy            # Deploy to dev environment
	@echo   make deploy ENV=prod   # Deploy to prod environment
	@echo   make logs              # View all logs
	@echo   make status            # Check deployment status

check-prerequisites: ## Check if required tools are installed
	@echo Checking prerequisites...
	@kubectl version --client >nul 2>&1 || ( echo kubectl is required but not installed. && exit /b 1 )
	@docker --version >nul 2>&1 || ( echo Docker is required but not installed. && exit /b 1 )
	@kubectl cluster-info >nul 2>&1 || ( echo Kubernetes cluster is not accessible. && exit /b 1 )
	@echo All prerequisites met!

setup-env: ## Copy .env.example to .env (if not exists)
	@if not exist .env ( \
		echo Creating .env file from template... && \
		copy .env.example .env && \
		echo .env file created. Please edit it with your actual values. && \
		echo Don't forget to update passwords, JWT secret, and API keys! \
	) else ( \
		echo .env file already exists. \
	)

create-namespace: check-prerequisites ## Create Kubernetes namespace
	@echo Creating namespace: $(NAMESPACE)
	@$(KUBECTL) create namespace $(NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo Namespace $(NAMESPACE) created/updated.

create-secrets: create-namespace ## Create Kubernetes secrets from .env file
	@if not exist .env ( \
		echo .env file not found. Run 'make setup-env' first and edit the .env file. && \
		exit /b 1 \
	)
	@echo Creating secrets from .env file...
	@$(KUBECTL) create secret generic autocare360-secrets \
		--from-env-file=.env \
		-n $(NAMESPACE) \
		--dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo Secrets created/updated successfully.

validate: ## Validate Kubernetes manifests
	@echo Validating Kubernetes manifests...
	@$(KUBECTL) apply -k $(KUSTOMIZE_PATH) --dry-run=client --validate=true
	@echo Manifests are valid!

deploy: check-prerequisites create-secrets ## Deploy the application to Kubernetes
	@echo Deploying AutoCare360 to $(ENV) environment...
	@$(KUBECTL) apply -k $(KUSTOMIZE_PATH) --validate=false
	@echo Deployment initiated. Use 'make status' to check progress.

status: ## Check deployment status
	@echo Checking deployment status...
	@echo.
	@echo Namespace:
	@$(KUBECTL) get namespace $(NAMESPACE) 2>nul || echo Namespace $(NAMESPACE) not found
	@echo.
	@echo Pods:
	@$(KUBECTL) get pods -n $(NAMESPACE) -o wide 2>nul || echo No pods found in namespace $(NAMESPACE)
	@echo.
	@echo Services:
	@$(KUBECTL) get svc -n $(NAMESPACE) 2>nul || echo No services found in namespace $(NAMESPACE)
	@echo.
	@echo Deployments:
	@$(KUBECTL) get deployments -n $(NAMESPACE) 2>nul || echo No deployments found in namespace $(NAMESPACE)
	@echo.
	@echo ConfigMaps:
	@$(KUBECTL) get configmap -n $(NAMESPACE) 2>nul || echo No configmaps found in namespace $(NAMESPACE)
	@echo.
	@echo Secrets:
	@$(KUBECTL) get secrets -n $(NAMESPACE) 2>nul || echo No secrets found in namespace $(NAMESPACE)

wait-ready: ## Wait for all deployments to be ready
	@echo Waiting for deployments to be ready...
	@$(KUBECTL) wait --for=condition=ready pod -l app=mysql -n $(NAMESPACE) --timeout=300s 2>nul || echo MySQL timeout (might still be starting)
	@$(KUBECTL) wait --for=condition=ready pod -l app=redis -n $(NAMESPACE) --timeout=300s 2>nul || echo Redis timeout (might still be starting)
	@$(KUBECTL) wait --for=condition=ready pod -l app=autocare360-backend -n $(NAMESPACE) --timeout=300s 2>nul || echo Backend timeout (might still be starting)
	@$(KUBECTL) wait --for=condition=ready pod -l app=autocare360-frontend -n $(NAMESPACE) --timeout=300s 2>nul || echo Frontend timeout (might still be starting)
	@$(KUBECTL) wait --for=condition=ready pod -l app=autocare360-chatbot -n $(NAMESPACE) --timeout=300s 2>nul || echo Chatbot timeout (might still be starting)
	@echo Deployments are ready!

logs: ## View logs from all services
	@echo Recent logs from all services:
	@echo:
	@echo === MySQL Logs ====
	@$(KUBECTL) logs deployment/mysql -n $(NAMESPACE) --tail=20 2>nul || echo MySQL not found
	@echo:
	@echo === Redis Logs ====
	@$(KUBECTL) logs deployment/redis -n $(NAMESPACE) --tail=20 2>nul || echo Redis not found
	@echo:
	@echo === Backend Logs ====
	@$(KUBECTL) logs deployment/autocare360-backend -n $(NAMESPACE) --tail=20 2>nul || echo Backend not found
	@echo:
	@echo === Frontend Logs ====
	@$(KUBECTL) logs deployment/autocare360-frontend -n $(NAMESPACE) --tail=20 2>nul || echo Frontend not found
	@echo:
	@echo === Chatbot Logs ====
	@$(KUBECTL) logs deployment/autocare360-chatbot -n $(NAMESPACE) --tail=20 2>nul || echo Chatbot not found

logs-backend: ## View backend logs (follow mode)
	@echo Following backend logs...
	@$(KUBECTL) logs -f deployment/autocare360-backend -n $(NAMESPACE)

logs-frontend: ## View frontend logs (follow mode)
	@echo Following frontend logs...
	@$(KUBECTL) logs -f deployment/autocare360-frontend -n $(NAMESPACE)

logs-chatbot: ## View chatbot logs (follow mode)
	@echo Following chatbot logs...
	@$(KUBECTL) logs -f deployment/autocare360-chatbot -n $(NAMESPACE)

logs-mysql: ## View MySQL logs (follow mode)
	@echo Following MySQL logs...
	@$(KUBECTL) logs -f deployment/mysql -n $(NAMESPACE)

logs-redis: ## View Redis logs (follow mode)
	@echo Following Redis logs...
	@$(KUBECTL) logs -f deployment/redis -n $(NAMESPACE)

restart: ## Restart all deployments
	@echo Restarting all deployments...
	@$(KUBECTL) rollout restart deployment/autocare360-backend -n $(NAMESPACE) 2>nul || echo Backend deployment not found
	@$(KUBECTL) rollout restart deployment/autocare360-frontend -n $(NAMESPACE) 2>nul || echo Frontend deployment not found
	@$(KUBECTL) rollout restart deployment/autocare360-chatbot -n $(NAMESPACE) 2>nul || echo Chatbot deployment not found
	@echo Restart initiated for all deployments.

restart-backend: ## Restart backend deployment
	@echo Restarting backend deployment...
	@$(KUBECTL) rollout restart deployment/autocare360-backend -n $(NAMESPACE)

restart-frontend: ## Restart frontend deployment
	@echo Restarting frontend deployment...
	@$(KUBECTL) rollout restart deployment/autocare360-frontend -n $(NAMESPACE)

restart-chatbot: ## Restart chatbot deployment
	@echo Restarting chatbot deployment...
	@$(KUBECTL) rollout restart deployment/autocare360-chatbot -n $(NAMESPACE)

update-secrets: ## Update secrets from .env file and restart deployments
	@echo Updating secrets and restarting deployments...
	@make create-secrets
	@make restart
	@echo Secrets updated and deployments restarted.

port-forward: ## Set up port forwarding for all services (run in background)
	@echo Setting up port forwarding...
	@echo Starting port forwarding in background...
	@echo Frontend: http://localhost:3000
	@start /b $(KUBECTL) port-forward -n $(NAMESPACE) svc/autocare360-frontend-service 3000:3000
	@echo Backend: http://localhost:8080
	@start /b $(KUBECTL) port-forward -n $(NAMESPACE) svc/autocare360-backend-service 8080:8080
	@echo Chatbot: http://localhost:8000
	@start /b $(KUBECTL) port-forward -n $(NAMESPACE) svc/autocare360-chatbot-service 8000:8000
	@echo Port forwarding started. Use Ctrl+C to stop all.
	@echo Access URLs:
	@echo   Frontend: http://localhost:3000
	@echo   Backend API: http://localhost:8080
	@echo   Backend Health: http://localhost:8080/actuator/health
	@echo   Chatbot API: http://localhost:8000
	@echo   Chatbot Health: http://localhost:8000/health

access: ## Show how to access services via port-forwarding
	@echo Access URLs (requires port-forwarding):
	@echo =========================================
	@echo Frontend: http://localhost:3000
	@echo Backend API: http://localhost:8080
	@echo Chatbot API: http://localhost:8000
	@echo.
	@echo To enable access, run: make port-forward
	@echo Then open http://localhost:3000 in your browser

minikube-urls: ## Get minikube service URLs
	@echo Getting minikube service URLs...
	@minikube service list -n $(NAMESPACE)
	@echo.
	@echo To open services in browser:
	@echo minikube service autocare360-frontend-service -n $(NAMESPACE)
	@echo minikube service autocare360-backend-service -n $(NAMESPACE)
	@echo minikube service autocare360-chatbot-service -n $(NAMESPACE)

setup-ingress: ## Setup NGINX Ingress Controller for localhost access
	@echo Setting up NGINX Ingress Controller...
	@$(KUBECTL) apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
	@echo Waiting for ingress controller to be ready...
	@$(KUBECTL) wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s
	@echo Ingress controller ready!
	@echo.
	@echo Add this to your hosts file (C:\Windows\System32\drivers\etc\hosts):
	@echo 127.0.0.1 autocare360.local
	@echo.
	@echo Then access via: http://autocare360.local or http://localhost

port-forward-frontend: ## Port forward frontend only
	@echo Port forwarding frontend...
	@echo Frontend available at: http://localhost:3000
	@$(KUBECTL) port-forward -n $(NAMESPACE) svc/autocare360-frontend-service 3000:3000

port-forward-backend: ## Port forward backend only
	@echo Port forwarding backend...
	@echo Backend available at: http://localhost:8080
	@$(KUBECTL) port-forward -n $(NAMESPACE) svc/autocare360-backend-service 8080:8080

port-forward-chatbot: ## Port forward chatbot only
	@echo Port forwarding chatbot...
	@echo Chatbot available at: http://localhost:8000
	@$(KUBECTL) port-forward -n $(NAMESPACE) svc/autocare360-chatbot-service 8000:8000

describe: ## Describe all resources for debugging
	@echo Describing all resources...
	@echo:
	@echo === Pods ====
	@$(KUBECTL) describe pods -n $(NAMESPACE) 2>nul || echo No pods found
	@echo:
	@echo === Services ====
	@$(KUBECTL) describe svc -n $(NAMESPACE) 2>nul || echo No services found
	@echo:
	@echo === Deployments ====
	@$(KUBECTL) describe deployments -n $(NAMESPACE) 2>nul || echo No deployments found

events: ## Show recent events
	@echo Recent events in namespace $(NAMESPACE):
	@$(KUBECTL) get events -n $(NAMESPACE) --sort-by='.lastTimestamp' 2>nul || echo No events found

clean: ## Delete all resources (WARNING: This will delete everything!)
	@echo WARNING: This will delete all AutoCare360 resources!
	@echo Are you sure? This action cannot be undone.
	@set /p confirm="Type 'yes' to continue: "
	@if "%confirm%"=="yes" ( \
		echo Deleting all resources... && \
		$(KUBECTL) delete namespace $(NAMESPACE) 2>nul || echo Namespace not found && \
		echo All resources deleted. \
	) else ( \
		echo Operation cancelled. \
	)

clean-deployments: ## Delete only deployments (keep namespace and secrets)
	@echo Deleting deployments...
	@$(KUBECTL) delete -k $(KUSTOMIZE_PATH) 2>nul || echo Some resources not found
	@echo Deployments deleted.

shell-backend: ## Get shell access to backend pod
	@echo Getting shell access to backend pod...
	@$(KUBECTL) exec -it deployment/autocare360-backend -n $(NAMESPACE) -- /bin/bash

shell-mysql: ## Get shell access to MySQL pod
	@echo Getting shell access to MySQL pod...
	@$(KUBECTL) exec -it deployment/mysql -n $(NAMESPACE) -- /bin/bash

mysql-cli: ## Connect to MySQL CLI
	@echo Connecting to MySQL CLI...
	@$(KUBECTL) exec -it deployment/mysql -n $(NAMESPACE) -- mysql -u root -p

redis-cli: ## Connect to Redis CLI
	@echo Connecting to Redis CLI...
	@$(KUBECTL) exec -it deployment/redis -n $(NAMESPACE) -- redis-cli

# Quick deployment workflow
quick-deploy: setup-env deploy wait-ready ## Quick setup and deployment workflow
	@echo Quick deployment completed!
	@echo Next steps:
	@echo 1. Run 'make port-forward' to access services locally
	@echo 2. Run 'make status' to check deployment status
	@echo 3. Run 'make logs' to view application logs

# Production deployment workflow
prod-deploy: ## Deploy to production (requires ENV=prod)
	@if not "$(ENV)"=="prod" ( \
		echo Error: Use 'make prod-deploy ENV=prod' for production deployment && \
		exit /b 1 \
	)
	@echo WARNING: Deploying to PRODUCTION environment!
	@echo Make sure you have:
	@echo   1. Updated .env with production values
	@echo   2. Strong passwords and JWT secret
	@echo   3. Production API keys
	@echo   4. Correct CORS origins
	@set /p confirm="Continue with production deployment? (yes/no): "
	@if "%confirm%"=="yes" ( \
		make deploy ENV=prod && \
		make wait-ready ENV=prod && \
		echo Production deployment completed! \
	) else ( \
		echo Operation cancelled. \
	)

# Development helpers
dev-reset: clean-deployments quick-deploy ## Reset development environment
	@echo Development environment reset completed!

tail-logs: ## Tail logs from all services
	@echo Tailing logs from all services (Ctrl+C to stop)...
	@start /b $(KUBECTL) logs -f -l app=autocare360-backend -n $(NAMESPACE) --prefix=true
	@start /b $(KUBECTL) logs -f -l app=autocare360-frontend -n $(NAMESPACE) --prefix=true
	@start /b $(KUBECTL) logs -f -l app=autocare360-chatbot -n $(NAMESPACE) --prefix=true
	@pause