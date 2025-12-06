#!/bin/bash

set -e

CLUSTER_NAME="crossplane-cluster"
NAMESPACE="crossplane-system"
PROVIDER_NAMESPACE="crossplane-providers"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_message "$BLUE" "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command_exists docker; then
        missing_tools+=("docker")
    fi
    
    if ! command_exists kind; then
        missing_tools+=("kind")
    fi
    
    if ! command_exists kubectl; then
        missing_tools+=("kubectl")
    fi
    
    if ! command_exists helm; then
        missing_tools+=("helm")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_message "$RED" "Missing required tools: ${missing_tools[*]}"
        print_message "$YELLOW" "Please install the missing tools before proceeding."
        print_message "$YELLOW" "Installation guide:"
        print_message "$YELLOW" "  - Docker: https://docs.docker.com/get-docker/"
        print_message "$YELLOW" "  - Kind: brew install kind"
        print_message "$YELLOW" "  - kubectl: brew install kubectl"
        print_message "$YELLOW" "  - Helm: brew install helm"
        exit 1
    fi
    
    print_message "$GREEN" "All prerequisites are met!"
}

# Function to create kind cluster
create_cluster() {
    print_message "$BLUE" "Creating Kind cluster..."
    
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        print_message "$YELLOW" "Cluster '${CLUSTER_NAME}' already exists."
        read -p "Do you want to delete and recreate it? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            delete_cluster
        else
            print_message "$YELLOW" "Using existing cluster."
            return
        fi
    fi
    
    kind create cluster --name "${CLUSTER_NAME}" --config config/kind-config.yaml
    
    print_message "$GREEN" "Cluster created successfully!"
    
    # Wait for cluster to be ready
    print_message "$BLUE" "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    print_message "$GREEN" "Cluster is ready!"
}

# Function to install Crossplane
install_crossplane() {
    print_message "$BLUE" "Installing Crossplane..."
    
    # Add Crossplane Helm repository
    helm repo add crossplane-stable https://charts.crossplane.io/stable
    helm repo update
    
    # Install Crossplane
    helm install crossplane \
        --namespace ${NAMESPACE} \
        --create-namespace \
        crossplane-stable/crossplane \
        --wait
    
    print_message "$GREEN" "Crossplane installed successfully!"
    
    # Wait for Crossplane to be ready
    print_message "$BLUE" "Waiting for Crossplane pods to be ready..."
    kubectl wait --for=condition=Available deployment/crossplane --namespace ${NAMESPACE} --timeout=300s
    kubectl wait --for=condition=Available deployment/crossplane-rbac-manager --namespace ${NAMESPACE} --timeout=300s
    
    print_message "$GREEN" "Crossplane is ready!"
}

# Function to install Crossplane CLI
install_crossplane_cli() {
    print_message "$BLUE" "Checking Crossplane CLI..."
    
    if ! command_exists kubectl-crossplane; then
        print_message "$YELLOW" "Crossplane CLI not found. Installing..."
        
        # Download and install crossplane CLI
        curl -sL "https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh" | sh
        
        # The script creates a file called 'crossplane' in the current directory
        if [ -f "./crossplane" ]; then
            sudo mv ./crossplane /usr/local/bin/kubectl-crossplane 2>/dev/null || \
                mv ./crossplane /usr/local/bin/kubectl-crossplane 2>/dev/null || \
                print_message "$YELLOW" "Could not move CLI to /usr/local/bin. You can install it manually."
        elif [ -f "./kubectl-crossplane" ]; then
            sudo mv ./kubectl-crossplane /usr/local/bin/kubectl-crossplane 2>/dev/null || \
                mv ./kubectl-crossplane /usr/local/bin/kubectl-crossplane 2>/dev/null || \
                print_message "$YELLOW" "Could not move CLI to /usr/local/bin. You can install it manually."
        fi
        
        if command_exists kubectl-crossplane; then
            print_message "$GREEN" "Crossplane CLI installed!"
        else
            print_message "$YELLOW" "Crossplane CLI installation skipped (optional component)"
        fi
    else
        print_message "$GREEN" "Crossplane CLI already installed!"
    fi
}

# Function to install Kubernetes provider
install_kubernetes_provider() {
    print_message "$BLUE" "Installing Kubernetes Provider..."
    
    kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-kubernetes:v0.13.0
EOF
    
    print_message "$BLUE" "Waiting for provider to be healthy..."
    sleep 10
    
    # Wait for provider to be installed
    for i in {1..30}; do
        if kubectl get provider provider-kubernetes -o jsonpath='{.status.conditions[?(@.type=="Healthy")].status}' 2>/dev/null | grep -q "True"; then
            print_message "$GREEN" "Kubernetes Provider installed successfully!"
            return
        fi
        echo -n "."
        sleep 5
    done
    
    print_message "$YELLOW" "Provider installation may still be in progress. Check with: kubectl get providers"
}

# Function to configure Kubernetes provider
configure_kubernetes_provider() {
    print_message "$BLUE" "Configuring Kubernetes Provider..."
    
    # Create ServiceAccount for provider
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: provider-kubernetes
  namespace: ${NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: provider-kubernetes
subjects:
- kind: ServiceAccount
  name: provider-kubernetes
  namespace: ${NAMESPACE}
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

    sleep 5
    
    # Create ProviderConfig
    kubectl apply -f - <<EOF
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kubernetes-provider
spec:
  credentials:
    source: InjectedIdentity
EOF
    
    print_message "$GREEN" "Kubernetes Provider configured successfully!"
}

# Function to create example resources
create_examples() {
    print_message "$BLUE" "Creating example resources..."
    
    # Create examples directory if it doesn't exist
    mkdir -p examples
    
    # Create example namespace using Crossplane
    cat > examples/example-namespace.yaml <<EOF
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: example-namespace
spec:
  forProvider:
    manifest:
      apiVersion: v1
      kind: Namespace
      metadata:
        name: crossplane-example
        labels:
          managed-by: crossplane
  providerConfigRef:
    name: kubernetes-provider
EOF
    
    # Create example deployment using Crossplane
    cat > examples/example-deployment.yaml <<EOF
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: example-deployment
spec:
  forProvider:
    manifest:
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: nginx-deployment
        namespace: crossplane-example
      spec:
        replicas: 2
        selector:
          matchLabels:
            app: nginx
        template:
          metadata:
            labels:
              app: nginx
          spec:
            containers:
            - name: nginx
              image: nginx:1.21
              ports:
              - containerPort: 80
  providerConfigRef:
    name: kubernetes-provider
EOF

    # Create example service using Crossplane
    cat > examples/example-service.yaml <<EOF
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: example-service
spec:
  forProvider:
    manifest:
      apiVersion: v1
      kind: Service
      metadata:
        name: nginx-service
        namespace: crossplane-example
      spec:
        selector:
          app: nginx
        ports:
        - protocol: TCP
          port: 80
          targetPort: 80
        type: ClusterIP
  providerConfigRef:
    name: kubernetes-provider
EOF
    
    print_message "$GREEN" "Example files created in 'examples/' directory!"
}

# Main installation flow
main() {
    print_message "$BLUE" "=========================================="
    print_message "$BLUE" "Crossplane on Kind - Setup Script"
    print_message "$BLUE" "=========================================="
    echo
    
    check_prerequisites
    create_cluster
    install_crossplane
    install_crossplane_cli
    install_kubernetes_provider
    configure_kubernetes_provider
    create_examples
    
    echo
    print_message "$GREEN" "=========================================="
    print_message "$GREEN" "Installation Complete!"
    print_message "$GREEN" "=========================================="
    echo
    print_message "$BLUE" "Cluster Information:"
    kubectl cluster-info --context "kind-${CLUSTER_NAME}"
    echo
    print_message "$BLUE" "Crossplane Status:"
    kubectl get pods -n ${NAMESPACE}
    echo
    print_message "$BLUE" "Installed Providers:"
    kubectl get providers
    echo
    print_message "$YELLOW" "Next Steps:"
    print_message "$YELLOW" "1. Apply example resources: kubectl apply -f examples/"
    print_message "$YELLOW" "2. Check resources: kubectl get object"
    print_message "$YELLOW" "3. Use the menu.sh script for easy management"
    echo
}

# Function to delete cluster
delete_cluster() {
    print_message "$BLUE" "Deleting Kind cluster..."
    kind delete cluster --name "${CLUSTER_NAME}"
    print_message "$GREEN" "Cluster deleted successfully!"
}

# Run main function
main
