# AutoCare360 Infrastructure
.PHONY: setup clean status start stop restart logs

# Variables
NAMESPACE := autocare360
KUBECTL := kubectl
DOCKER := docker

# Detect OS
ifeq ($(OS),Windows_NT)
	SHELL := powershell.exe
	.SHELLFLAGS := -NoProfile -Command
	RM := Remove-Item -Recurse -Force
	MKDIR := New-Item -ItemType Directory -Force
	CP := Copy-Item
	TEST_FILE := Test-Path
	NULL := >$$null 2>&1
else
	RM := rm -rf
	MKDIR := mkdir -p
	CP := cp
	TEST_FILE := test -f
	NULL := >/dev/null 2>&1
endif

# Setup everything
setup:
	@echo "Setting up AutoCare360..."
ifeq ($(OS),Windows_NT)
	@if (-not (Test-Path .env)) { Copy-Item .env.example .env }
	@$(KUBECTL) create namespace $(NAMESPACE) 2>$$null; if ($$?) {} else { echo "Namespace exists" }
else
	@test -f .env || cp .env.example .env
	@$(KUBECTL) create namespace $(NAMESPACE) 2>/dev/null || echo "Namespace exists"
endif
	@$(KUBECTL) create secret generic autocare360-secrets --from-env-file=.env -n $(NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(KUBECTL) create configmap autocare360-config --from-env-file=.env -n $(NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
ifeq ($(OS),Windows_NT)
	@if (Test-Path ..\dev-autocare360-backend) { cd ..\dev-autocare360-backend; $(DOCKER) build -t ghcr.io/colabdevelopers/dev-autocare360-backend:latest . }
	@if (Test-Path ..\dev-autocare360-frontend) { cd ..\dev-autocare360-frontend; $(DOCKER) build -t ghcr.io/colabdevelopers/dev-autocare360-frontend:latest . }
	@if (Test-Path ..\autocare360-chatbot) { cd ..\autocare360-chatbot; $(DOCKER) build -t ghcr.io/colabdevelopers/autocare360-chatbot:latest . }
else
	@if [ -d ../dev-autocare360-backend ]; then cd ../dev-autocare360-backend && $(DOCKER) build -t ghcr.io/colabdevelopers/dev-autocare360-backend:latest .; fi
	@if [ -d ../dev-autocare360-frontend ]; then cd ../dev-autocare360-frontend && $(DOCKER) build -t ghcr.io/colabdevelopers/dev-autocare360-frontend:latest .; fi
	@if [ -d ../autocare360-chatbot ]; then cd ../autocare360-chatbot && $(DOCKER) build -t ghcr.io/colabdevelopers/autocare360-chatbot:latest .; fi
endif
	@$(KUBECTL) apply -k deployment/kubernetes/overlays/dev/
	@echo ""
	@echo "Setup complete!"
	@echo ""
	@echo "Run: make start"

# Start all services
start:
	@echo "Starting all services in background..."
ifeq ($(OS),Windows_NT)
	@Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n $(NAMESPACE) svc/autocare360-frontend-service 3000:3000"
	@Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n $(NAMESPACE) svc/autocare360-backend-service 8080:8080"
	@Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n $(NAMESPACE) svc/autocare360-chatbot-service 5000:8000"
else
	@$(KUBECTL) port-forward -n $(NAMESPACE) svc/autocare360-frontend-service 3000:3000 > /dev/null 2>&1 & \
	$(KUBECTL) port-forward -n $(NAMESPACE) svc/autocare360-backend-service 8080:8080 > /dev/null 2>&1 & \
	$(KUBECTL) port-forward -n $(NAMESPACE) svc/autocare360-chatbot-service 5000:8000 > /dev/null 2>&1 &
endif
	@echo ""
	@echo "Services started:"
	@echo "  Frontend: http://localhost:3000"
	@echo "  Backend:  http://localhost:8080"
	@echo "  Chatbot:  http://localhost:5000"
	@echo ""
ifeq ($(OS),Windows_NT)
	@echo "Close the PowerShell windows to stop port forwarding"
else
	@echo "Run 'make stop' to stop port forwarding"
endif

	@echo "Run 'make stop' to stop port forwarding"

# Show status
status:
	@$(KUBECTL) get deployments,pods,svc -n $(NAMESPACE)

# Restart all deployments
restart:
	@$(KUBECTL) rollout restart deployment -n $(NAMESPACE)

# Stop port forwarding
stop:
ifeq ($(OS),Windows_NT)
	@Get-Process | Where-Object {$$_.CommandLine -like "*port-forward*$(NAMESPACE)*"} | Stop-Process -Force 2>$$null; echo "Port forwarding stopped"
else
	@pkill -f "port-forward.*$(NAMESPACE)" || killall kubectl || echo "Port forwarding stopped"
endif

# Delete everything
clean:
	@$(KUBECTL) delete namespace $(NAMESPACE)

# Show logs (usage: make logs POD=backend)
logs:
	@$(KUBECTL) logs -f -n $(NAMESPACE) -l app=autocare360-$(POD) --tail=100
