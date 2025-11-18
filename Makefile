# AutoCare360 Infrastructure Makefile
.PHONY: help setup deploy start stop restart status clean logs

NAMESPACE := autocare360
KUBECTL := kubectl

# Default target
.DEFAULT_GOAL := help

## help: Display this help message
help:
	@echo "AutoCare360 Infrastructure - Available Commands:"
	@echo ""
	@echo "  make setup     - Initial setup (namespace, secrets, deploy)"
	@echo "  make deploy    - Deploy/update all services to Kubernetes"
	@echo "  make start     - Start port-forwarding for API access"
	@echo "  make stop      - Stop port-forwarding"
	@echo "  make restart   - Restart all deployments"
	@echo "  make status    - Show status of all resources"
	@echo "  make logs      - Show logs (usage: make logs POD=backend)"
	@echo "  make clean     - Delete everything (namespace and all resources)"
	@echo ""
	@echo "Access URLs:"
	@echo "  Frontend:  http://localhost:30000 (NodePort - always available)"
	@echo "  Backend:   http://localhost:8080 (requires: make start)"
	@echo "  Chatbot:   http://localhost:8000 (requires: make start)"
	@echo ""

## setup: Initial setup - create namespace, secrets, and deploy
setup:
	@echo "Setting up AutoCare360..."
	@test -f .env || (echo "Creating .env from template..." && cp .env.example .env && echo "Edit .env with your actual values before deploying!")
	@$(KUBECTL) create namespace $(NAMESPACE) 2>/dev/null || echo "Namespace already exists"
	@$(KUBECTL) create secret generic autocare360-secrets --from-env-file=.env -n $(NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@echo "Secrets configured"
	@$(KUBECTL) apply -k deployment/kubernetes/overlays/dev/
	@echo ""
	@echo "Setup complete!"
	@echo ""
	@echo "Waiting for pods to be ready..."
	@$(KUBECTL) wait --for=condition=ready pod -l app=mysql -n $(NAMESPACE) --timeout=120s 2>/dev/null || echo "MySQL taking longer than expected"
	@$(KUBECTL) wait --for=condition=ready pod -l app=redis -n $(NAMESPACE) --timeout=120s 2>/dev/null || echo "Redis taking longer than expected"
	@echo ""
	@echo "Frontend available at: http://localhost:30000"
	@echo "For API access, run: make start"
	@echo ""

## deploy: Deploy or update all services
deploy:
	@echo "Deploying AutoCare360 services..."
	@$(KUBECTL) apply -k deployment/kubernetes/overlays/dev/
	@echo "Deployment applied!"
	@echo ""
	@make status

## start: Start port-forwarding for backend and chatbot API access
start:
	@echo "Starting port-forwarding..."
	@$(KUBECTL) port-forward -n $(NAMESPACE) svc/autocare360-backend-service 8080:8080 > /dev/null 2>&1 & \
	$(KUBECTL) port-forward -n $(NAMESPACE) svc/autocare360-chatbot-service 8000:8000 > /dev/null 2>&1 &
	@sleep 2
	@echo "Port-forwarding started!"
	@echo ""
	@echo "Access URLs:"
	@echo "  Frontend:  http://localhost:30000 (NodePort)"
	@echo "  Backend:   http://localhost:8080 (API)"
	@echo "  Chatbot:   http://localhost:8000 (API)"
	@echo ""
	@echo "Run 'make stop' to stop port-forwarding"
	@echo ""

## stop: Stop all port-forwarding
stop:
	@echo "Stopping port-forwarding..."
	@pkill -f "port-forward.*$(NAMESPACE)" 2>/dev/null || echo "No port-forwarding processes found"
	@echo "Port-forwarding stopped"

## restart: Restart all deployments (rolling update)
restart:
	@echo "Restarting all deployments..."
	@$(KUBECTL) rollout restart deployment -n $(NAMESPACE)
	@echo "Restart triggered!"
	@echo ""
	@echo "Monitor progress with: make status"

## status: Show status of all resources
status:
	@echo "AutoCare360 Status:"
	@echo ""
	@echo "=== Pods ==="
	@$(KUBECTL) get pods -n $(NAMESPACE)
	@echo ""
	@echo "=== Services ==="
	@$(KUBECTL) get svc -n $(NAMESPACE)
	@echo ""
	@echo "=== Deployments ==="
	@$(KUBECTL) get deployments -n $(NAMESPACE)
	@echo ""
	@echo "=== Ingress ==="
	@$(KUBECTL) get ingress -n $(NAMESPACE) 2>/dev/null || echo "No ingress configured"

## clean: Delete the namespace and all resources
clean:
	@echo "WARNING: This will delete the entire $(NAMESPACE) namespace!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	@echo "Deleting namespace..."
	@$(KUBECTL) delete namespace $(NAMESPACE)
	@echo "Namespace deleted"

## logs: Show logs for a specific service (usage: make logs POD=backend)
logs:
	@if [ -z "$(POD)" ]; then \
		echo "Error: POD parameter required"; \
		echo "Usage: make logs POD=backend|frontend|chatbot"; \
		exit 1; \
	fi
	@echo "Logs for autocare360-$(POD):"
	@echo ""
	@$(KUBECTL) logs -f -n $(NAMESPACE) -l app=autocare360-$(POD) --tail=100
