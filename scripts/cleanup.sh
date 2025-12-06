#!/bin/bash

# Cleanup script for Crossplane on Kind
# This script provides complete cleanup options

set -e

CLUSTER_NAME="crossplane-cluster"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

print_header() {
    echo
    print_message "$BLUE" "=========================================="
    print_message "$BLUE" "  Crossplane on Kind - Cleanup Script"
    print_message "$BLUE" "=========================================="
    echo
}

show_menu() {
    print_header
    print_message "$YELLOW" "Select cleanup option:"
    echo "1. Delete Crossplane resources only (keep cluster)"
    echo "2. Delete cluster only (remove everything)"
    echo "3. Delete cluster and cleanup local files"
    echo "4. Cancel"
    echo
    read -p "Select option [1-4]: " choice
    
    case $choice in
        1) cleanup_resources ;;
        2) cleanup_cluster ;;
        3) cleanup_all ;;
        4) exit 0 ;;
        *) print_message "$RED" "Invalid option"; show_menu ;;
    esac
}

cleanup_resources() {
    print_message "$BLUE" "Cleaning up Crossplane resources..."
    
    # Delete all managed objects
    print_message "$YELLOW" "Deleting managed objects..."
    kubectl delete object --all --all-namespaces --ignore-not-found=true
    
    # Delete example namespace if exists
    print_message "$YELLOW" "Deleting example namespace..."
    kubectl delete namespace crossplane-example --ignore-not-found=true
    
    # Delete compositions
    print_message "$YELLOW" "Deleting compositions..."
    kubectl delete compositions --all --ignore-not-found=true
    
    # Delete XRDs
    print_message "$YELLOW" "Deleting XRDs..."
    kubectl delete xrds --all --ignore-not-found=true
    
    print_message "$GREEN" "Resources cleanup complete!"
    print_message "$YELLOW" "Note: Providers and Crossplane itself are still installed."
    print_message "$YELLOW" "To completely remove everything, delete the cluster."
}

cleanup_cluster() {
    print_message "$BLUE" "Deleting Kind cluster..."
    
    if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        print_message "$YELLOW" "Cluster does not exist!"
        exit 0
    fi
    
    read -p "Are you sure you want to delete the cluster? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kind delete cluster --name "${CLUSTER_NAME}"
        print_message "$GREEN" "Cluster deleted successfully!"
    else
        print_message "$YELLOW" "Deletion cancelled."
    fi
}

cleanup_all() {
    print_message "$RED" "Complete cleanup - This will remove everything!"
    
    read -p "Are you sure? This action cannot be undone (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "$YELLOW" "Cleanup cancelled."
        exit 0
    fi
    
    # Delete cluster
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        print_message "$BLUE" "Deleting cluster..."
        kind delete cluster --name "${CLUSTER_NAME}"
        print_message "$GREEN" "Cluster deleted!"
    fi
    
    # Clean up local files
    print_message "$BLUE" "Cleaning up local files..."
    rm -rf examples/
    
    print_message "$GREEN" "Complete cleanup finished!"
    print_message "$YELLOW" "Note: Configuration files (kind-config.yaml, scripts) are preserved."
}

show_menu
