#!/bin/bash

# Docker and System Check for macOS
# This helps diagnose TLS handshake timeout issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

print_message "$BLUE" "=========================================="
print_message "$BLUE" "Docker & System Diagnostics (macOS)"
print_message "$BLUE" "=========================================="
echo

# Check Docker
print_message "$BLUE" "1. Checking Docker Status..."
if docker info >/dev/null 2>&1; then
    print_message "$GREEN" "   ✓ Docker is running"
    
    # Get Docker resources
    print_message "$BLUE" "   Docker Resources:"
    docker info 2>/dev/null | grep -E "CPUs:|Total Memory:" || true
else
    print_message "$RED" "   ✗ Docker is not running"
    exit 1
fi

echo

# Check Docker version
print_message "$BLUE" "2. Docker Version:"
docker version --format '   Client: {{.Client.Version}}' 2>/dev/null
docker version --format '   Server: {{.Server.Version}}' 2>/dev/null

echo

# Check existing containers
print_message "$BLUE" "3. Existing Kind Clusters:"
kind get clusters | while read cluster; do
    echo "   - $cluster"
done

echo

# Count running containers
RUNNING_CONTAINERS=$(docker ps -q | wc -l | tr -d ' ')
print_message "$BLUE" "4. Running Docker Containers: $RUNNING_CONTAINERS"

if [ "$RUNNING_CONTAINERS" -gt 10 ]; then
    print_message "$YELLOW" "   ⚠ You have many containers running ($RUNNING_CONTAINERS)"
    print_message "$YELLOW" "   This might cause resource issues"
fi

echo

# Check Docker networks
print_message "$BLUE" "5. Docker Networks:"
docker network ls | grep kind || print_message "$YELLOW" "   No kind networks found"

echo

# Recommendations
print_message "$BLUE" "=========================================="
print_message "$BLUE" "Recommendations for TLS Timeout Issues"
print_message "$BLUE" "=========================================="
echo

print_message "$YELLOW" "Common fixes for 'TLS handshake timeout':"
echo
print_message "$GREEN" "1. Increase Docker Resources (Recommended)"
echo "   Open Docker Desktop -> Preferences -> Resources"
echo "   Recommended: CPUs: 4+, Memory: 8GB+"
echo
print_message "$GREEN" "2. Restart Docker Desktop"
echo "   Click Docker icon -> Quit Docker Desktop"
echo "   Reopen Docker Desktop"
echo
print_message "$GREEN" "3. Clean up unused containers/networks"
echo "   docker system prune -a --volumes"
echo
print_message "$GREEN" "4. Stop other Kind clusters"
existing_clusters=$(kind get clusters 2>/dev/null | grep -v crossplane || true)
if [ -n "$existing_clusters" ]; then
    echo "   You have these clusters running:"
    echo "$existing_clusters" | while read cluster; do
        echo "     docker stop \$(docker ps -q --filter 'name=$cluster')"
    done
fi
echo
print_message "$GREEN" "5. Use simpler cluster config (fewer resources)"
echo "   We can create a minimal 1-node cluster for testing"
echo

print_message "$BLUE" "=========================================="
print_message "$BLUE" "Next Steps"
print_message "$BLUE" "=========================================="
echo
print_message "$YELLOW" "Choose one:"
echo "  A. Fix resources and retry: ./setup.sh"
echo "  B. Use minimal cluster: ./setup-minimal.sh (we'll create this)"
echo "  C. Stop other clusters first, then retry"
echo
