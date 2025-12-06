# Crossplane on Kind - Getting Started

## Prerequisites

Before starting, ensure you have:
- Docker Desktop installed and running
- Homebrew (for macOS) or package manager for Linux
- At least 4GB RAM available for Docker
- 10GB free disk space

## Installation Steps

### Step 1: Install Required Tools

For macOS:
```bash
# Install Kind
brew install kind

# Install kubectl
brew install kubectl

# Install Helm
brew install helm
```

For Linux:
```bash
# Install Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Step 2: Verify Installation

```bash
docker --version
kind --version
kubectl version --client
helm version
```

### Step 3: Setup Crossplane

```bash
# Make scripts executable
chmod +x setup.sh menu.sh status.sh cleanup.sh

# Run setup
./setup.sh
```

The setup script will:
1. Check all prerequisites
2. Create a Kind cluster with 1 control plane and 2 worker nodes
3. Install Crossplane using Helm
4. Install and configure the Kubernetes provider
5. Create example resource files

### Step 4: Verify Setup

```bash
# Check cluster status
./status.sh

# Or manually
kubectl get nodes
kubectl get pods -n crossplane-system
kubectl get providers
```

## Using the Menu System

The interactive menu provides easy access to all operations:

```bash
./menu.sh
```

### Menu Options

1. **Cluster Management**
   - Create, delete, stop, start, restart cluster
   - View cluster information

2. **Resource Management**
   - List and manage Crossplane resources
   - Apply and delete examples
   - Cleanup operations

3. **Monitoring**
   - View status and logs
   - Watch resources
   - Check events

4. **Examples**
   - Apply example resources
   - Create AWS provider examples

5. **Documentation**
   - Access guides and troubleshooting

## Quick Examples

### Example 1: Create a Namespace

```bash
# Apply example
kubectl apply -f examples/example-namespace.yaml

# Check status
kubectl get object example-namespace

# Verify namespace was created
kubectl get namespace crossplane-example
```

### Example 2: Deploy Application

```bash
# Apply all examples
kubectl apply -f examples/

# Check status
kubectl get object

# Verify resources
kubectl get all -n crossplane-example
```

### Example 3: Using the Menu

```bash
# Start menu
./menu.sh

# Navigate to Examples -> Apply All Examples
# This will apply all example resources
```

## Common Operations

### Start/Stop Cluster

```bash
# Using menu
./menu.sh
# Select: Cluster Management -> Stop/Start Cluster

# Or using Docker
docker stop $(docker ps -q --filter "name=crossplane-cluster")
docker start $(docker ps -aq --filter "name=crossplane-cluster")
```

### Check Status

```bash
# Quick status
./status.sh

# Detailed status
kubectl get all -n crossplane-system
kubectl get providers
kubectl get object
```

### View Logs

```bash
# Crossplane core logs
kubectl logs -n crossplane-system -l app=crossplane -f

# Provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-kubernetes -f
```

### Cleanup

```bash
# Interactive cleanup
./cleanup.sh

# Options:
# 1. Delete resources only
# 2. Delete cluster only
# 3. Complete cleanup
```

## Troubleshooting

### Issue: Cluster won't start

```bash
# Check Docker
docker ps

# Check Kind
kind get clusters

# Recreate cluster
kind delete cluster --name crossplane-cluster
./setup.sh
```

### Issue: Provider not healthy

```bash
# Check provider status
kubectl get providers

# Describe provider
kubectl describe provider provider-kubernetes

# Check logs
kubectl logs -n crossplane-system $(kubectl get pods -n crossplane-system -l pkg.crossplane.io/provider=provider-kubernetes -o name)
```

### Issue: Resources not creating

```bash
# Check object status
kubectl get object
kubectl describe object <resource-name>

# Check events
kubectl get events -n crossplane-system

# Check provider config
kubectl get providerconfigs
```

## Next Steps

1. **Explore Examples**: Review and modify examples in the `examples/` directory
2. **Create Compositions**: Build reusable infrastructure abstractions
3. **Add Providers**: Install AWS, Azure, or GCP providers
4. **Integrate GitOps**: Use ArgoCD or Flux for automated deployments
5. **Build Platform**: Create custom APIs and compositions for your team

## Additional Resources

- Full documentation: See README.md
- Crossplane docs: https://docs.crossplane.io/
- Provider marketplace: https://marketplace.upbound.io/
- Community Slack: https://slack.crossplane.io/

## Support

For help:
1. Check troubleshooting section in README.md
2. Run `./menu.sh` -> Documentation -> Troubleshooting Guide
3. Review logs: `./menu.sh` -> Monitoring -> View Logs
4. Check Crossplane documentation
5. Join Crossplane Slack community
