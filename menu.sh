#!/bin/bash

set -e

CLUSTER_NAME="crossplane-cluster"
NAMESPACE="crossplane-system"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Function to print header
print_header() {
    clear
    print_message "$CYAN" "=========================================="
    print_message "$CYAN" "  Crossplane on Kind - Management Menu"
    print_message "$CYAN" "=========================================="
    echo
}

# Function to pause
pause() {
    echo
    read -p "Press Enter to continue..." -r
}

# Function to check if cluster exists
cluster_exists() {
    kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"
}

# Function to check if cluster is running
cluster_running() {
    if cluster_exists; then
        docker ps --filter "name=${CLUSTER_NAME}-control-plane" --format "{{.Status}}" | grep -q "Up"
        return $?
    fi
    return 1
}

# Main Menu
show_main_menu() {
    print_header
    print_message "$BLUE" "Main Menu:"
    echo "1. Cluster Management"
    echo "2. Crossplane Resources Management"
    echo "3. Monitoring & Status"
    echo "4. Examples"
    echo "5. Documentation"
    echo "6. Exit"
    echo
    read -p "Select an option [1-6]: " choice
    
    case $choice in
        1) cluster_management_menu ;;
        2) resources_management_menu ;;
        3) monitoring_menu ;;
        4) examples_menu ;;
        5) documentation_menu ;;
        6) exit 0 ;;
        *) print_message "$RED" "Invalid option"; pause; show_main_menu ;;
    esac
}

# Cluster Management Menu
cluster_management_menu() {
    print_header
    print_message "$BLUE" "Cluster Management:"
    echo "1. Create Cluster"
    echo "2. Delete Cluster"
    echo "3. Stop Cluster"
    echo "4. Start Cluster"
    echo "5. Restart Cluster"
    echo "6. Cluster Info"
    echo "7. Back to Main Menu"
    echo
    read -p "Select an option [1-7]: " choice
    
    case $choice in
        1) create_cluster ;;
        2) delete_cluster ;;
        3) stop_cluster ;;
        4) start_cluster ;;
        5) restart_cluster ;;
        6) cluster_info ;;
        7) show_main_menu ;;
        *) print_message "$RED" "Invalid option"; pause; cluster_management_menu ;;
    esac
}

# Function to create cluster
create_cluster() {
    print_header
    print_message "$BLUE" "Creating Crossplane Cluster..."
    echo
    
    if cluster_exists; then
        print_message "$YELLOW" "Cluster already exists!"
        read -p "Do you want to delete and recreate it? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ./setup.sh
        else
            print_message "$YELLOW" "Cluster creation cancelled."
        fi
    else
        ./setup.sh
    fi
    
    pause
    cluster_management_menu
}

# Function to delete cluster
delete_cluster() {
    print_header
    print_message "$RED" "Delete Cluster"
    echo
    
    if ! cluster_exists; then
        print_message "$YELLOW" "Cluster does not exist!"
        pause
        cluster_management_menu
        return
    fi
    
    print_message "$YELLOW" "WARNING: This will permanently delete the cluster and all resources!"
    read -p "Are you sure you want to delete the cluster? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message "$BLUE" "Deleting cluster..."
        kind delete cluster --name "${CLUSTER_NAME}"
        print_message "$GREEN" "Cluster deleted successfully!"
    else
        print_message "$YELLOW" "Cluster deletion cancelled."
    fi
    
    pause
    cluster_management_menu
}

# Function to stop cluster
stop_cluster() {
    print_header
    print_message "$BLUE" "Stopping Cluster..."
    echo
    
    if ! cluster_exists; then
        print_message "$YELLOW" "Cluster does not exist!"
        pause
        cluster_management_menu
        return
    fi
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is already stopped!"
        pause
        cluster_management_menu
        return
    fi
    
    print_message "$BLUE" "Stopping all cluster containers..."
    docker ps --filter "name=${CLUSTER_NAME}" --format "{{.Names}}" | while read container; do
        print_message "$BLUE" "Stopping ${container}..."
        docker stop "$container"
    done
    
    print_message "$GREEN" "Cluster stopped successfully!"
    print_message "$YELLOW" "Note: Use 'Start Cluster' to resume the cluster."
    
    pause
    cluster_management_menu
}

# Function to start cluster
start_cluster() {
    print_header
    print_message "$BLUE" "Starting Cluster..."
    echo
    
    if ! cluster_exists; then
        print_message "$YELLOW" "Cluster does not exist! Please create it first."
        pause
        cluster_management_menu
        return
    fi
    
    if cluster_running; then
        print_message "$YELLOW" "Cluster is already running!"
        pause
        cluster_management_menu
        return
    fi
    
    print_message "$BLUE" "Starting all cluster containers..."
    docker ps -a --filter "name=${CLUSTER_NAME}" --format "{{.Names}}" | while read container; do
        print_message "$BLUE" "Starting ${container}..."
        docker start "$container"
    done
    
    print_message "$BLUE" "Waiting for cluster to be ready..."
    sleep 10
    kubectl wait --for=condition=Ready nodes --all --timeout=300s 2>/dev/null || true
    
    print_message "$GREEN" "Cluster started successfully!"
    
    pause
    cluster_management_menu
}

# Function to restart cluster
restart_cluster() {
    print_header
    print_message "$BLUE" "Restarting Cluster..."
    echo
    
    if ! cluster_exists; then
        print_message "$YELLOW" "Cluster does not exist!"
        pause
        cluster_management_menu
        return
    fi
    
    stop_cluster
    sleep 5
    start_cluster
}

# Function to show cluster info
cluster_info() {
    print_header
    print_message "$BLUE" "Cluster Information"
    echo
    
    if ! cluster_exists; then
        print_message "$YELLOW" "Cluster does not exist!"
        pause
        cluster_management_menu
        return
    fi
    
    if cluster_running; then
        print_message "$GREEN" "Cluster Status: Running"
        echo
        print_message "$BLUE" "Cluster Info:"
        kubectl cluster-info --context "kind-${CLUSTER_NAME}"
        echo
        print_message "$BLUE" "Nodes:"
        kubectl get nodes
        echo
        print_message "$BLUE" "Cluster Resources:"
        kubectl top nodes 2>/dev/null || print_message "$YELLOW" "Metrics not available (metrics-server not installed)"
    else
        print_message "$YELLOW" "Cluster Status: Stopped"
    fi
    
    pause
    cluster_management_menu
}

# Resources Management Menu
resources_management_menu() {
    print_header
    print_message "$BLUE" "Crossplane Resources Management:"
    echo "1. List All Resources"
    echo "2. List Providers"
    echo "3. List Provider Configs"
    echo "4. List Managed Resources (Objects)"
    echo "5. Delete Specific Resource"
    echo "6. Delete All Example Resources"
    echo "7. Cleanup All Crossplane Resources"
    echo "8. Back to Main Menu"
    echo
    read -p "Select an option [1-8]: " choice
    
    case $choice in
        1) list_all_resources ;;
        2) list_providers ;;
        3) list_provider_configs ;;
        4) list_managed_resources ;;
        5) delete_specific_resource ;;
        6) delete_example_resources ;;
        7) cleanup_all_resources ;;
        8) show_main_menu ;;
        *) print_message "$RED" "Invalid option"; pause; resources_management_menu ;;
    esac
}

# Function to list all resources
list_all_resources() {
    print_header
    print_message "$BLUE" "All Crossplane Resources:"
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        resources_management_menu
        return
    fi
    
    print_message "$BLUE" "Providers:"
    kubectl get providers
    echo
    print_message "$BLUE" "Provider Configs:"
    kubectl get providerconfigs
    echo
    print_message "$BLUE" "Managed Objects:"
    kubectl get object
    echo
    print_message "$BLUE" "Compositions:"
    kubectl get compositions
    echo
    print_message "$BLUE" "Composite Resource Definitions:"
    kubectl get xrds
    
    pause
    resources_management_menu
}

# Function to list providers
list_providers() {
    print_header
    print_message "$BLUE" "Installed Providers:"
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        resources_management_menu
        return
    fi
    
    kubectl get providers
    echo
    print_message "$BLUE" "Provider Details:"
    kubectl get providers -o wide
    
    pause
    resources_management_menu
}

# Function to list provider configs
list_provider_configs() {
    print_header
    print_message "$BLUE" "Provider Configurations:"
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        resources_management_menu
        return
    fi
    
    kubectl get providerconfigs --all-namespaces
    
    pause
    resources_management_menu
}

# Function to list managed resources
list_managed_resources() {
    print_header
    print_message "$BLUE" "Managed Resources (Objects):"
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        resources_management_menu
        return
    fi
    
    kubectl get object
    echo
    print_message "$BLUE" "Detailed View:"
    kubectl get object -o wide
    
    pause
    resources_management_menu
}

# Function to delete specific resource
delete_specific_resource() {
    print_header
    print_message "$BLUE" "Delete Specific Resource"
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        resources_management_menu
        return
    fi
    
    print_message "$BLUE" "Available Resources:"
    kubectl get object
    echo
    read -p "Enter resource name to delete: " resource_name
    
    if [ -z "$resource_name" ]; then
        print_message "$YELLOW" "No resource name provided!"
        pause
        resources_management_menu
        return
    fi
    
    read -p "Are you sure you want to delete '$resource_name'? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete object "$resource_name"
        print_message "$GREEN" "Resource deleted successfully!"
    else
        print_message "$YELLOW" "Deletion cancelled."
    fi
    
    pause
    resources_management_menu
}

# Function to delete example resources
delete_example_resources() {
    print_header
    print_message "$BLUE" "Delete Example Resources"
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        resources_management_menu
        return
    fi
    
    print_message "$YELLOW" "This will delete all resources created from examples/ directory."
    read -p "Are you sure? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -d "examples" ]; then
            print_message "$BLUE" "Deleting example resources..."
            kubectl delete -f examples/ --ignore-not-found=true
            print_message "$GREEN" "Example resources deleted successfully!"
        else
            print_message "$YELLOW" "Examples directory not found!"
        fi
    else
        print_message "$YELLOW" "Deletion cancelled."
    fi
    
    pause
    resources_management_menu
}

# Function to cleanup all resources
cleanup_all_resources() {
    print_header
    print_message "$RED" "Cleanup All Crossplane Resources"
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        resources_management_menu
        return
    fi
    
    print_message "$YELLOW" "WARNING: This will delete all Crossplane managed resources!"
    print_message "$YELLOW" "This includes all Objects, Compositions, and XRDs."
    print_message "$YELLOW" "Providers and Crossplane itself will NOT be removed."
    read -p "Are you sure? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message "$BLUE" "Deleting all managed objects..."
        kubectl delete object --all --all-namespaces --ignore-not-found=true
        
        print_message "$BLUE" "Deleting all compositions..."
        kubectl delete compositions --all --ignore-not-found=true
        
        print_message "$BLUE" "Deleting all XRDs..."
        kubectl delete xrds --all --ignore-not-found=true
        
        print_message "$GREEN" "All resources cleaned up successfully!"
    else
        print_message "$YELLOW" "Cleanup cancelled."
    fi
    
    pause
    resources_management_menu
}

# Monitoring Menu
monitoring_menu() {
    print_header
    print_message "$BLUE" "Monitoring & Status:"
    echo "1. Crossplane Status"
    echo "2. Watch Crossplane Pods"
    echo "3. View Crossplane Logs"
    echo "4. Provider Status"
    echo "5. Resource Status"
    echo "6. Events"
    echo "7. Back to Main Menu"
    echo
    read -p "Select an option [1-7]: " choice
    
    case $choice in
        1) crossplane_status ;;
        2) watch_crossplane_pods ;;
        3) view_crossplane_logs ;;
        4) provider_status ;;
        5) resource_status ;;
        6) view_events ;;
        7) show_main_menu ;;
        *) print_message "$RED" "Invalid option"; pause; monitoring_menu ;;
    esac
}

# Function to show Crossplane status
crossplane_status() {
    print_header
    print_message "$BLUE" "Crossplane Status:"
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        monitoring_menu
        return
    fi
    
    print_message "$BLUE" "Crossplane Pods:"
    kubectl get pods -n ${NAMESPACE}
    echo
    print_message "$BLUE" "Crossplane Deployments:"
    kubectl get deployments -n ${NAMESPACE}
    echo
    print_message "$BLUE" "Crossplane Version:"
    kubectl get deployment crossplane -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].image}' && echo
    
    pause
    monitoring_menu
}

# Function to watch Crossplane pods
watch_crossplane_pods() {
    print_header
    print_message "$BLUE" "Watching Crossplane Pods (Press Ctrl+C to exit)..."
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        monitoring_menu
        return
    fi
    
    kubectl get pods -n ${NAMESPACE} -w
    
    monitoring_menu
}

# Function to view Crossplane logs
view_crossplane_logs() {
    print_header
    print_message "$BLUE" "Crossplane Logs"
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        monitoring_menu
        return
    fi
    
    print_message "$BLUE" "Select component:"
    echo "1. Crossplane Core"
    echo "2. RBAC Manager"
    echo "3. Provider Kubernetes"
    read -p "Select [1-3]: " choice
    
    case $choice in
        1)
            pod=$(kubectl get pods -n ${NAMESPACE} -l app=crossplane -o jsonpath='{.items[0].metadata.name}')
            kubectl logs -n ${NAMESPACE} "$pod" -f
            ;;
        2)
            pod=$(kubectl get pods -n ${NAMESPACE} -l app=crossplane-rbac-manager -o jsonpath='{.items[0].metadata.name}')
            kubectl logs -n ${NAMESPACE} "$pod" -f
            ;;
        3)
            pod=$(kubectl get pods -n ${NAMESPACE} -l pkg.crossplane.io/provider=provider-kubernetes -o jsonpath='{.items[0].metadata.name}')
            kubectl logs -n ${NAMESPACE} "$pod" -f
            ;;
        *)
            print_message "$RED" "Invalid option"
            ;;
    esac
    
    pause
    monitoring_menu
}

# Function to show provider status
provider_status() {
    print_header
    print_message "$BLUE" "Provider Status:"
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        monitoring_menu
        return
    fi
    
    kubectl get providers
    echo
    print_message "$BLUE" "Detailed Status:"
    kubectl describe providers
    
    pause
    monitoring_menu
}

# Function to show resource status
resource_status() {
    print_header
    print_message "$BLUE" "Resource Status:"
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        monitoring_menu
        return
    fi
    
    print_message "$BLUE" "Managed Objects:"
    kubectl get object
    echo
    print_message "$BLUE" "Select a resource to see details (or press Enter to skip):"
    read -p "Resource name: " resource_name
    
    if [ -n "$resource_name" ]; then
        kubectl describe object "$resource_name"
    fi
    
    pause
    monitoring_menu
}

# Function to view events
view_events() {
    print_header
    print_message "$BLUE" "Cluster Events:"
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        monitoring_menu
        return
    fi
    
    kubectl get events --all-namespaces --sort-by='.lastTimestamp'
    
    pause
    monitoring_menu
}

# Examples Menu
examples_menu() {
    print_header
    print_message "$BLUE" "Examples:"
    echo "1. Apply All Examples"
    echo "2. Apply Namespace Example"
    echo "3. Apply Deployment Example"
    echo "4. Apply Service Example"
    echo "5. View Example Files"
    echo "6. Create AWS Provider Example"
    echo "7. Back to Main Menu"
    echo
    read -p "Select an option [1-7]: " choice
    
    case $choice in
        1) apply_all_examples ;;
        2) apply_namespace_example ;;
        3) apply_deployment_example ;;
        4) apply_service_example ;;
        5) view_example_files ;;
        6) create_aws_example ;;
        7) show_main_menu ;;
        *) print_message "$RED" "Invalid option"; pause; examples_menu ;;
    esac
}

# Function to apply all examples
apply_all_examples() {
    print_header
    print_message "$BLUE" "Applying All Examples..."
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        examples_menu
        return
    fi
    
    if [ -d "examples" ]; then
        kubectl apply -f examples/
        print_message "$GREEN" "All examples applied successfully!"
        echo
        print_message "$BLUE" "Checking status..."
        sleep 5
        kubectl get object
    else
        print_message "$YELLOW" "Examples directory not found! Please run setup.sh first."
    fi
    
    pause
    examples_menu
}

# Function to apply namespace example
apply_namespace_example() {
    print_header
    print_message "$BLUE" "Applying Namespace Example..."
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        examples_menu
        return
    fi
    
    if [ -f "examples/example-namespace.yaml" ]; then
        kubectl apply -f examples/example-namespace.yaml
        print_message "$GREEN" "Namespace example applied successfully!"
    else
        print_message "$YELLOW" "Example file not found!"
    fi
    
    pause
    examples_menu
}

# Function to apply deployment example
apply_deployment_example() {
    print_header
    print_message "$BLUE" "Applying Deployment Example..."
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        examples_menu
        return
    fi
    
    if [ -f "examples/example-deployment.yaml" ]; then
        kubectl apply -f examples/example-deployment.yaml
        print_message "$GREEN" "Deployment example applied successfully!"
    else
        print_message "$YELLOW" "Example file not found!"
    fi
    
    pause
    examples_menu
}

# Function to apply service example
apply_service_example() {
    print_header
    print_message "$BLUE" "Applying Service Example..."
    echo
    
    if ! cluster_running; then
        print_message "$YELLOW" "Cluster is not running!"
        pause
        examples_menu
        return
    fi
    
    if [ -f "examples/example-service.yaml" ]; then
        kubectl apply -f examples/example-service.yaml
        print_message "$GREEN" "Service example applied successfully!"
    else
        print_message "$YELLOW" "Example file not found!"
    fi
    
    pause
    examples_menu
}

# Function to view example files
view_example_files() {
    print_header
    print_message "$BLUE" "Example Files:"
    echo
    
    if [ -d "examples" ]; then
        for file in examples/*.yaml; do
            if [ -f "$file" ]; then
                print_message "$GREEN" "File: $(basename $file)"
                print_message "$YELLOW" "---"
                cat "$file"
                echo
                echo "---"
                echo
            fi
        done
    else
        print_message "$YELLOW" "Examples directory not found!"
    fi
    
    pause
    examples_menu
}

# Function to create AWS example
create_aws_example() {
    print_header
    print_message "$BLUE" "Creating AWS Provider Example..."
    echo
    
    print_message "$YELLOW" "This will create example files for AWS provider configuration."
    print_message "$YELLOW" "Note: You'll need to configure AWS credentials separately."
    echo
    read -p "Continue? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "$YELLOW" "Cancelled."
        pause
        examples_menu
        return
    fi
    
    mkdir -p examples/aws
    
    cat > examples/aws/provider-aws.yaml <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws
spec:
  package: xpkg.upbound.io/upbound/provider-aws:v0.40.0
EOF
    
    cat > examples/aws/provider-config-aws.yaml <<EOF
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-secret
      key: creds
EOF
    
    cat > examples/aws/example-s3-bucket.yaml <<EOF
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: crossplane-example-bucket-12345
spec:
  forProvider:
    region: us-east-1
  providerConfigRef:
    name: default
EOF
    
    print_message "$GREEN" "AWS example files created in examples/aws/"
    echo
    print_message "$BLUE" "To use these examples:"
    print_message "$YELLOW" "1. Install the provider: kubectl apply -f examples/aws/provider-aws.yaml"
    print_message "$YELLOW" "2. Create AWS credentials secret:"
    print_message "$YELLOW" "   kubectl create secret generic aws-secret -n crossplane-system --from-file=creds=./aws-credentials.txt"
    print_message "$YELLOW" "3. Apply provider config: kubectl apply -f examples/aws/provider-config-aws.yaml"
    print_message "$YELLOW" "4. Create resources: kubectl apply -f examples/aws/example-s3-bucket.yaml"
    
    pause
    examples_menu
}

# Documentation Menu
documentation_menu() {
    print_header
    print_message "$BLUE" "Documentation:"
    echo "1. View README"
    echo "2. Crossplane Quick Start"
    echo "3. Provider Documentation"
    echo "4. Troubleshooting Guide"
    echo "5. Back to Main Menu"
    echo
    read -p "Select an option [1-5]: " choice
    
    case $choice in
        1) view_readme ;;
        2) quick_start_guide ;;
        3) provider_documentation ;;
        4) troubleshooting_guide ;;
        5) show_main_menu ;;
        *) print_message "$RED" "Invalid option"; pause; documentation_menu ;;
    esac
}

# Function to view README
view_readme() {
    print_header
    print_message "$BLUE" "README.md"
    echo
    
    if [ -f "README.md" ]; then
        less README.md
    else
        print_message "$YELLOW" "README.md not found!"
    fi
    
    pause
    documentation_menu
}

# Function to show quick start guide
quick_start_guide() {
    print_header
    print_message "$BLUE" "Crossplane Quick Start Guide"
    echo
    
    print_message "$GREEN" "Step 1: Create the cluster"
    print_message "$YELLOW" "Use option 1.1 from the Cluster Management menu or run: ./setup.sh"
    echo
    
    print_message "$GREEN" "Step 2: Verify installation"
    print_message "$YELLOW" "kubectl get pods -n crossplane-system"
    print_message "$YELLOW" "kubectl get providers"
    echo
    
    print_message "$GREEN" "Step 3: Apply examples"
    print_message "$YELLOW" "Use option 4.1 from the Examples menu or run: kubectl apply -f examples/"
    echo
    
    print_message "$GREEN" "Step 4: Check resources"
    print_message "$YELLOW" "kubectl get object"
    print_message "$YELLOW" "kubectl get namespaces crossplane-example"
    echo
    
    pause
    documentation_menu
}

# Function to show provider documentation
provider_documentation() {
    print_header
    print_message "$BLUE" "Provider Documentation"
    echo
    
    print_message "$GREEN" "Kubernetes Provider:"
    print_message "$YELLOW" "The Kubernetes provider allows you to manage Kubernetes resources using Crossplane."
    echo
    print_message "$YELLOW" "Package: xpkg.upbound.io/crossplane-contrib/provider-kubernetes"
    print_message "$YELLOW" "Documentation: https://marketplace.upbound.io/providers/crossplane-contrib/provider-kubernetes"
    echo
    
    print_message "$GREEN" "AWS Provider:"
    print_message "$YELLOW" "Package: xpkg.upbound.io/upbound/provider-aws"
    print_message "$YELLOW" "Documentation: https://marketplace.upbound.io/providers/upbound/provider-aws"
    echo
    
    print_message "$GREEN" "Azure Provider:"
    print_message "$YELLOW" "Package: xpkg.upbound.io/upbound/provider-azure"
    print_message "$YELLOW" "Documentation: https://marketplace.upbound.io/providers/upbound/provider-azure"
    echo
    
    print_message "$GREEN" "GCP Provider:"
    print_message "$YELLOW" "Package: xpkg.upbound.io/upbound/provider-gcp"
    print_message "$YELLOW" "Documentation: https://marketplace.upbound.io/providers/upbound/provider-gcp"
    echo
    
    pause
    documentation_menu
}

# Function to show troubleshooting guide
troubleshooting_guide() {
    print_header
    print_message "$BLUE" "Troubleshooting Guide"
    echo
    
    print_message "$GREEN" "Common Issues:"
    echo
    
    print_message "$YELLOW" "1. Provider not healthy"
    print_message "$BLUE" "   Check: kubectl get providers"
    print_message "$BLUE" "   Debug: kubectl describe provider <provider-name>"
    print_message "$BLUE" "   Logs: kubectl logs -n crossplane-system <provider-pod>"
    echo
    
    print_message "$YELLOW" "2. Resources not creating"
    print_message "$BLUE" "   Check: kubectl get object"
    print_message "$BLUE" "   Debug: kubectl describe object <resource-name>"
    print_message "$BLUE" "   Events: kubectl get events --all-namespaces"
    echo
    
    print_message "$YELLOW" "3. Cluster won't start"
    print_message "$BLUE" "   Check Docker: docker ps -a"
    print_message "$BLUE" "   Check Kind: kind get clusters"
    print_message "$BLUE" "   Recreate: Use option 1.2 to delete, then 1.1 to create"
    echo
    
    print_message "$YELLOW" "4. Permission errors"
    print_message "$BLUE" "   Verify ServiceAccount: kubectl get sa -n crossplane-system"
    print_message "$BLUE" "   Check RBAC: kubectl get clusterrolebinding provider-kubernetes"
    echo
    
    pause
    documentation_menu
}

# Start the menu
show_main_menu
