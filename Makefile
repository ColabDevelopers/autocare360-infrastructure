# Makefile for AutoCare360 Infrastructure

ROOT_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: deploy-dev deploy-down deploy-prod

# Deploy to local development environment using Kubernetes
deploy-dev:
	cd $(ROOT_DIR)../dev-autocare360-backend && \
	docker build -t ghcr.io/colabdevelopers/dev-autocare360-backend:latest . && \
	kubectl create namespace autocare360 --dry-run=client -o yaml | kubectl apply -f - && \
	kubectl create secret generic autocare360-secrets --from-env-file=.env -n autocare360 --dry-run=client -o yaml | kubectl apply -f - && \
	cd ../deployment/kubernetes && \
	kubectl apply -k overlays/dev/

# Stop local development deployment
deploy-down:
	cd ../deployment/kubernetes && \
	kubectl delete -k overlays/dev/ && \
	kubectl delete secret autocare360-secrets -n autocare360 --ignore-not-found=true && \
	kubectl delete namespace autocare360 --ignore-not-found=true

# Deploy to production environment using Kubernetes
deploy-prod:
	cd $(ROOT_DIR)../dev-autocare360-backend && \
	docker build -t ghcr.io/colabdevelopers/dev-autocare360-backend:$(git rev-parse --short HEAD) . && \
	kubectl create namespace autocare360 --dry-run=client -o yaml | kubectl apply -f - && \
	kubectl create secret generic autocare360-secrets --from-env-file=.env.prod -n autocare360 --dry-run=client -o yaml | kubectl apply -f - && \
	cd ../deployment/kubernetes && \
	kubectl apply -k overlays/prod/