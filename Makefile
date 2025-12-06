.PHONY: help setup status menu cleanup start stop restart delete apply-examples clean-examples install check validate

# Default target
help:
	@echo "Crossplane on Kind - Makefile Commands"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make install      - Install required tools (macOS only)"
	@echo "  make check        - Check prerequisites"
	@echo "  make validate     - Validate setup and show correct commands"
	@echo "  make setup        - Create cluster and install Crossplane"
	@echo ""
	@echo "Management Commands:"
	@echo "  make menu         - Open interactive management menu"
	@echo "  make status       - Show cluster and Crossplane status"
	@echo "  make start        - Start the cluster"
	@echo "  make stop         - Stop the cluster"
	@echo "  make restart      - Restart the cluster"
	@echo "  make delete       - Delete the cluster"
	@echo ""
	@echo "Resource Commands:"
	@echo "  make apply-examples    - Apply all example resources"
	@echo "  make clean-examples    - Delete all example resources"
	@echo "  make list-resources    - List all Crossplane resources"
	@echo ""
	@echo "Cleanup Commands:"
	@echo "  make cleanup      - Interactive cleanup menu"
	@echo "  make clean-all    - Delete cluster and all resources"
	@echo ""
	@echo "Monitoring Commands:"
	@echo "  make logs         - View Crossplane logs"
	@echo "  make logs-provider - View provider logs"
	@echo "  make watch        - Watch Crossplane resources"
	@echo ""

# Install tools (macOS)
install:
	@echo "Installing required tools..."
	@command -v brew >/dev/null 2>&1 || { echo "Homebrew not found. Please install it first."; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "Please install Docker Desktop first."; exit 1; }
	@command -v kind >/dev/null 2>&1 || brew install kind
	@command -v kubectl >/dev/null 2>&1 || brew install kubectl
	@command -v helm >/dev/null 2>&1 || brew install helm
	@echo "All tools installed!"

# Check prerequisites
check:
	@echo "Checking prerequisites..."
	@command -v docker >/dev/null 2>&1 || { echo "Docker not found"; exit 1; }
	@command -v kind >/dev/null 2>&1 || { echo "Kind not found"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found"; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "Helm not found"; exit 1; }
	@echo "All prerequisites met!"

# Validate setup
validate:
	@./scripts/validate.sh

# Setup cluster
setup: check
	@./setup.sh

# Show status
status:
	@./scripts/status.sh

# Open menu
menu:
	@./menu.sh

# Cleanup
cleanup:
	@./scripts/cleanup.sh

# Start cluster
start:
	@echo "Starting cluster..."
	@docker start $$(docker ps -aq --filter "name=crossplane-cluster") || echo "Cluster not found"
	@echo "Waiting for cluster to be ready..."
	@sleep 10
	@kubectl wait --for=condition=Ready nodes --all --timeout=300s 2>/dev/null || echo "Cluster may not be ready yet"

# Stop cluster
stop:
	@echo "Stopping cluster..."
	@docker stop $$(docker ps -q --filter "name=crossplane-cluster") || echo "Cluster not running"

# Restart cluster
restart: stop
	@sleep 5
	@$(MAKE) start

# Delete cluster
delete:
	@echo "Deleting cluster..."
	@kind delete cluster --name crossplane-cluster || echo "Cluster not found"

# Apply examples
apply-examples:
	@echo "Applying example resources..."
	@kubectl apply -f examples/ 2>/dev/null || echo "Examples directory not found or cluster not running"
	@echo "Checking status..."
	@sleep 5
	@kubectl get object 2>/dev/null || true

# Clean examples
clean-examples:
	@echo "Deleting example resources..."
	@kubectl delete -f examples/ --ignore-not-found=true 2>/dev/null || echo "Examples not found or cluster not running"

# List resources
list-resources:
	@echo "Crossplane Providers:"
	@kubectl get providers 2>/dev/null || echo "Cluster not running"
	@echo ""
	@echo "Provider Configs:"
	@kubectl get providerconfigs 2>/dev/null || echo "No configs found"
	@echo ""
	@echo "Managed Resources:"
	@kubectl get object 2>/dev/null || echo "No resources found"

# View Crossplane logs
logs:
	@kubectl logs -n crossplane-system -l app=crossplane -f 2>/dev/null || echo "Cluster not running"

# View provider logs
logs-provider:
	@kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-kubernetes -f 2>/dev/null || echo "Provider not found"

# Watch resources
watch:
	@kubectl get object -w 2>/dev/null || echo "Cluster not running"

# Complete cleanup
clean-all:
	@echo "WARNING: This will delete the cluster and all resources!"
	@read -p "Are you sure? (y/n): " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		kind delete cluster --name crossplane-cluster; \
		rm -rf examples/; \
		echo "Cleanup complete!"; \
	else \
		echo "Cleanup cancelled."; \
	fi
