# Makefile for AutoCare360 Infrastructure

ROOT_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: build-all build-backend build-frontend build-chatbot deploy-dev deploy-down deploy-prod validate clean

# Build all Docker images
build-all: build-backend build-frontend build-chatbot

# Build backend image
build-backend:
	cd $(ROOT_DIR)../dev-autocare360-backend && \
	docker build -t ghcr.io/colabdevelopers/dev-autocare360-backend:latest .

# Build frontend image
build-frontend:
	cd $(ROOT_DIR)../dev-autocare360-frontend && \
	docker build -t ghcr.io/colabdevelopers/dev-autocare360-frontend:latest .

# Build chatbot image
build-chatbot:
	cd $(ROOT_DIR)../autocare360-chatbot && \
	docker build -t ghcr.io/colabdevelopers/autocare360-chatbot:latest .

# Deploy to local development environment using Kubernetes
deploy-dev: build-all
	kubectl create namespace autocare360 --dry-run=client -o yaml | kubectl apply -f - && \
	cd $(ROOT_DIR)deployment/kubernetes && \
	kubectl apply -k overlays/dev/

# Stop local development deployment
deploy-down:
	cd $(ROOT_DIR)deployment/kubernetes && \
	kubectl delete -k overlays/dev/ --ignore-not-found=true && \
	kubectl delete namespace autocare360 --ignore-not-found=true

# Deploy to production environment using Kubernetes
deploy-prod: build-all
	kubectl create namespace autocare360 --dry-run=client -o yaml | kubectl apply -f - && \
	cd $(ROOT_DIR)deployment/kubernetes && \
	kubectl apply -k overlays/prod/

# Validate Kubernetes manifests
validate:
	cd $(ROOT_DIR)deployment/kubernetes/overlays/dev && \
	kubectl kustomize . | kubectl apply --dry-run=client -f -

# Encode secrets for GitHub (helper function)
encode-secret:
	@echo "Usage: make encode-secret SECRET_NAME=value"
	@echo "Example: make encode-secret SECRET_NAME=JWT_SECRET SECRET_VALUE=your_secret_here"
	@if [ -z "$(SECRET_NAME)" ] || [ -z "$(SECRET_VALUE)" ]; then \
		echo "Error: SECRET_NAME and SECRET_VALUE must be provided"; \
		echo "Example: make encode-secret SECRET_NAME=JWT_SECRET SECRET_VALUE=your_secret_here"; \
		exit 1; \
	fi
	@echo "Base64 encoded $(SECRET_NAME):"
	@echo -n "$(SECRET_VALUE)" | base64

# Show help for encoding secrets
secrets-help:
	@echo "GitHub Secrets Encoding Help:"
	@echo "=============================="
	@echo "Use 'make encode-secret SECRET_NAME=<name> SECRET_VALUE=<value>' to encode secrets"
	@echo ""
	@echo "Required secrets:"
	@echo "- MYSQL_ROOT_PASSWORD"
	@echo "- MYSQL_DATABASE"
	@echo "- MYSQL_USER"
	@echo "- MYSQL_PASSWORD"
	@echo "- JWT_SECRET"
	@echo "- OPENAI_API_KEY"
	@echo "- DB_URL"
	@echo ""
	@echo "Example:"
	@echo "make encode-secret SECRET_NAME=JWT_SECRET SECRET_VALUE=my_secure_jwt_secret"
	docker rmi ghcr.io/colabdevelopers/dev-autocare360-frontend:latest --force || true
	docker rmi ghcr.io/colabdevelopers/autocare360-chatbot:latest --force || true