#!/bin/bash

# Validation script to check if everything is working correctly
# This helps avoid common command errors

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

print_header() {
    echo
    print_message "$BLUE" "=========================================="
    print_message "$BLUE" "$1"
    print_message "$BLUE" "=========================================="
}

# Check if crossplane-cluster exists
CLUSTER_NAME="crossplane-cluster"

print_header "Checking Environment"

# Check Docker
print_message "$BLUE" "Checking Docker..."
if command -v docker >/dev/null 2>&1 && docker ps >/dev/null 2>&1; then
    print_message "$GREEN" "✓ Docker is running"
else
    print_message "$RED" "✗ Docker is not running or not installed"
    exit 1
fi

# Check Kind
print_message "$BLUE" "Checking Kind..."
if command -v kind >/dev/null 2>&1; then
    print_message "$GREEN" "✓ Kind is installed"
else
    print_message "$RED" "✗ Kind is not installed"
    exit 1
fi

# Check kubectl
print_message "$BLUE" "Checking kubectl..."
if command -v kubectl >/dev/null 2>&1; then
    print_message "$GREEN" "✓ kubectl is installed"
else
    print_message "$RED" "✗ kubectl is not installed"
    exit 1
fi

# Check Helm
print_message "$BLUE" "Checking Helm..."
if command -v helm >/dev/null 2>&1; then
    print_message "$GREEN" "✓ Helm is installed"
else
    print_message "$RED" "✗ Helm is not installed"
    exit 1
fi

print_header "Checking Clusters"

# List all Kind clusters
print_message "$BLUE" "Available Kind clusters:"
kind get clusters

echo

# Check if crossplane-cluster exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    print_message "$GREEN" "✓ Crossplane cluster exists"
    
    # Check if running
    if docker ps --filter "name=${CLUSTER_NAME}-control-plane" --format "{{.Status}}" | grep -q "Up"; then
        print_message "$GREEN" "✓ Crossplane cluster is running"
        
        print_header "Cluster Information"
        
        # Switch to correct context
        kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null 2>&1
        
        # Get nodes
        print_message "$BLUE" "Nodes:"
        kubectl get nodes
        
        echo
        print_message "$BLUE" "Crossplane pods:"
        kubectl get pods -n crossplane-system 2>/dev/null || print_message "$YELLOW" "Crossplane not installed yet"
        
        echo
        print_message "$BLUE" "Providers:"
        kubectl get providers 2>/dev/null || print_message "$YELLOW" "No providers installed yet"
        
        echo
        print_message "$BLUE" "Managed Resources:"
        kubectl get object 2>/dev/null || print_message "$YELLOW" "No managed resources yet"
        
    else
        print_message "$YELLOW" "⚠ Crossplane cluster exists but is stopped"
        print_message "$BLUE" "To start: make start OR ./menu.sh → Cluster Management → Start Cluster"
    fi
else
    print_message "$YELLOW" "⚠ Crossplane cluster does not exist"
    print_message "$BLUE" "To create: ./setup.sh OR make setup"
fi

print_header "Current kubectl Context"
kubectl config current-context

print_header "Common Commands"
print_message "$YELLOW" "Correct commands to use:"
echo "  kind get clusters              # List Kind clusters"
echo "  kubectl get nodes              # List Kubernetes nodes"
echo "  kubectl cluster-info           # Get cluster info"
echo "  kubectl get pods -A            # List all pods"
echo "  kubectl get providers          # List Crossplane providers"
echo "  kubectl get object             # List managed resources"
echo ""
print_message "$RED" "WRONG command (causes error):"
echo "  kubectl get cluster            # ✗ This resource type doesn't exist"
echo ""
print_message "$GREEN" "Quick actions:"
echo "  ./setup.sh                     # Create cluster"
echo "  ./menu.sh                      # Interactive menu"
echo "  make status                    # Check status"
echo "  make help                      # Show all commands"

echo
