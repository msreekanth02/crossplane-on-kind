#!/bin/bash

# Quick Status Check Script
# Provides a quick overview of the Crossplane setup

CLUSTER_NAME="crossplane-cluster"
NAMESPACE="crossplane-system"

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

print_section() {
    echo
    print_message "$BLUE" "=========================================="
    print_message "$BLUE" "$1"
    print_message "$BLUE" "=========================================="
}

# Check if cluster exists
print_section "Cluster Status"
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    print_message "$GREEN" "Cluster exists: ${CLUSTER_NAME}"
    
    # Check if running
    if docker ps --filter "name=${CLUSTER_NAME}-control-plane" --format "{{.Status}}" | grep -q "Up"; then
        print_message "$GREEN" "Cluster is running"
        
        # Get cluster info
        echo
        kubectl cluster-info --context "kind-${CLUSTER_NAME}" 2>/dev/null || print_message "$YELLOW" "Unable to connect to cluster"
        
        # Check nodes
        print_section "Nodes"
        kubectl get nodes 2>/dev/null || print_message "$RED" "Unable to get nodes"
        
        # Check Crossplane
        print_section "Crossplane Status"
        kubectl get pods -n ${NAMESPACE} 2>/dev/null || print_message "$YELLOW" "Crossplane not installed or namespace doesn't exist"
        
        # Check providers
        print_section "Providers"
        kubectl get providers 2>/dev/null || print_message "$YELLOW" "No providers installed"
        
        # Check provider configs
        print_section "Provider Configurations"
        kubectl get providerconfigs 2>/dev/null || print_message "$YELLOW" "No provider configs found"
        
        # Check managed resources
        print_section "Managed Resources"
        kubectl get object 2>/dev/null || print_message "$YELLOW" "No managed resources found"
        
        # Check namespaces
        print_section "Namespaces"
        kubectl get namespaces | grep -E "NAME|crossplane|example" 2>/dev/null
        
    else
        print_message "$YELLOW" "Cluster exists but is not running"
        print_message "$BLUE" "Start the cluster with: ./menu.sh (option 1 -> 4)"
    fi
else
    print_message "$RED" "Cluster does not exist"
    print_message "$BLUE" "Create the cluster with: ./setup.sh"
fi

echo
print_section "Quick Commands"
print_message "$YELLOW" "Setup cluster:       ./setup.sh"
print_message "$YELLOW" "Management menu:     ./menu.sh"
print_message "$YELLOW" "Check status:        make status"
print_message "$YELLOW" "Cleanup:             make cleanup"
echo
