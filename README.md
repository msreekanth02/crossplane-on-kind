# Crossplane on Kind

A complete setup for running Crossplane on a local Kind (Kubernetes in Docker) cluster with automation scripts and comprehensive examples.

## Table of Contents

- [What is Crossplane?](#what-is-crossplane)
- [Why Use Crossplane?](#why-use-crossplane)
- [Crossplane vs Terraform](#crossplane-vs-terraform)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Usage](#usage)
- [Examples](#examples)
- [Architecture](#architecture)
- [Providers](#providers)
- [Management Operations](#management-operations)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [References](#references)

## Additional Documentation

- **[Quick Start Guide](docs/QUICKSTART.md)** - Get started in 5 minutes
- **[Getting Started Tutorial](docs/GETTING_STARTED.md)** - Step-by-step guide
- **[Command Cheatsheet](docs/CHEATSHEET.md)** - Quick command reference
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## What is Crossplane?

Crossplane is an open-source Kubernetes extension that transforms your cluster into a universal control plane. It enables you to manage any infrastructure or cloud service using Kubernetes API and kubectl.

### Key Features

- **Infrastructure as Code**: Define infrastructure using Kubernetes manifests
- **Unified API**: Manage multiple cloud providers through a single Kubernetes API
- **Composition**: Build reusable infrastructure components and abstractions
- **GitOps Ready**: Native integration with GitOps workflows
- **Kubernetes Native**: Uses familiar Kubernetes concepts and tools
- **Provider Ecosystem**: Extensive support for cloud providers and services

### Core Concepts

1. **Providers**: Enable Crossplane to manage external resources (AWS, Azure, GCP, Kubernetes, etc.)
2. **Managed Resources**: Individual infrastructure components (S3 buckets, VMs, databases)
3. **Composite Resources (XRs)**: Higher-level abstractions combining multiple managed resources
4. **Compositions**: Templates defining how to create managed resources from XRs
5. **ProviderConfigs**: Authentication and configuration for providers

## Why Use Crossplane?

### Benefits

1. **Kubernetes-Native Infrastructure Management**
   - Use kubectl and familiar Kubernetes tools
   - Leverage Kubernetes RBAC, namespaces, and policies
   - Integrate with existing Kubernetes workflows

2. **Multi-Cloud Abstraction**
   - Consistent API across different cloud providers
   - Reduce vendor lock-in
   - Simplified multi-cloud deployments

3. **Self-Service Infrastructure**
   - Enable developers to provision infrastructure
   - Platform teams define policies and abstractions
   - Reduced operational overhead

4. **GitOps Integration**
   - Declarative infrastructure definitions
   - Version control for infrastructure
   - Automated drift detection and reconciliation

5. **Composition and Reusability**
   - Create platform abstractions
   - Reusable infrastructure patterns
   - Simplified complexity for end users

### Use Cases

- **Platform Engineering**: Build internal developer platforms
- **Multi-Cloud Management**: Manage resources across multiple clouds
- **Self-Service Infrastructure**: Enable developer self-service
- **Kubernetes Cluster Management**: Manage Kubernetes clusters declaratively
- **Application Dependencies**: Provision infrastructure alongside applications

## Crossplane vs Terraform

Both Crossplane and Terraform are Infrastructure as Code tools, but they have different approaches and use cases.

### Similarities

- Declarative infrastructure definitions
- Support for multiple cloud providers
- State management and drift detection
- Plan/preview capabilities
- Modular and reusable code

### Key Differences

| Aspect | Crossplane | Terraform |
|--------|-----------|-----------|
| **Architecture** | Kubernetes-native, runs as controller | Standalone CLI tool |
| **API** | Kubernetes API (kubectl) | Terraform CLI (terraform) |
| **State Management** | Kubernetes etcd | State files (local or remote) |
| **Reconciliation** | Continuous reconciliation loop | On-demand apply |
| **Authentication** | Kubernetes RBAC | Provider-specific credentials |
| **Composition** | Kubernetes CRDs and Compositions | Modules and workspaces |
| **GitOps** | Native integration | Requires additional tooling |
| **Learning Curve** | Requires Kubernetes knowledge | Dedicated DSL (HCL) |
| **Deployment Model** | Always running in cluster | Run locally or in CI/CD |
| **Multi-Tenancy** | Kubernetes namespaces and RBAC | Workspaces and separate state |

### When to Choose Crossplane

- You're already using Kubernetes
- You want continuous reconciliation
- You need Kubernetes-native RBAC and multi-tenancy
- You want to build platform abstractions
- You prefer GitOps workflows
- You want self-service infrastructure for developers

### When to Choose Terraform

- You don't need Kubernetes
- You prefer a standalone tool
- You have existing Terraform code
- You need day-0 cluster provisioning
- You want a simpler learning curve
- You prefer on-demand operations

### Using Both Together

Many organizations use both:
- **Terraform**: For cluster provisioning and foundational infrastructure
- **Crossplane**: For application-level infrastructure and developer self-service

## Prerequisites

Before you begin, ensure you have the following tools installed:

- **Docker**: Container runtime (required for Kind)
- **Kind**: Kubernetes in Docker
- **kubectl**: Kubernetes command-line tool
- **Helm**: Kubernetes package manager
- **Bash**: Shell environment (macOS/Linux)

### Installation Commands (macOS)

```bash
# Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop

# Install Kind
brew install kind

# Install kubectl
brew install kubectl

# Install Helm
brew install helm
```

### Installation Commands (Linux)

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

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

## Quick Start

### Automated Setup

1. Clone or create the project directory:
```bash
mkdir -p crossplane-on-kind
cd crossplane-on-kind
```

2. Make scripts executable:
```bash
chmod +x setup.sh menu.sh
```

3. Run the automated setup:
```bash
./setup.sh
```

This will:
- Check prerequisites
- Create a Kind cluster (1 control plane + 2 worker nodes)
- Install Crossplane via Helm
- Install and configure the Kubernetes provider
- Create example resource files

4. Use the interactive menu:
```bash
./menu.sh
```

### Manual Setup

If you prefer manual steps:

1. Create the Kind cluster:
```bash
kind create cluster --name crossplane-cluster --config kind-config.yaml
```

2. Install Crossplane:
```bash
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane --namespace crossplane-system --create-namespace crossplane-stable/crossplane --wait
```

3. Install the Kubernetes provider:
```bash
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-kubernetes:v0.13.0
EOF
```

4. Configure the provider:
```bash
# Create ServiceAccount and RBAC
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: provider-kubernetes
  namespace: crossplane-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: provider-kubernetes
subjects:
- kind: ServiceAccount
  name: provider-kubernetes
  namespace: crossplane-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

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
```

## Project Structure

```
crossplane-on-kind/
├── README.md                      # Main documentation
├── Makefile                       # Command shortcuts
├── .gitignore                     # Git exclusions
│
├── setup.sh                       # Automated setup script
├── menu.sh                        # Interactive management menu
│
├── docs/                          # Documentation
│   ├── QUICKSTART.md              # Quick start guide
│   ├── GETTING_STARTED.md         # Step-by-step tutorial
│   ├── CHEATSHEET.md              # Command reference
│   └── TROUBLESHOOTING.md         # Problem-solving guide
│
├── scripts/                       # Utility scripts
│   ├── status.sh                  # Status checker
│   ├── cleanup.sh                 # Cleanup automation
│   ├── validate.sh                # Validation script
│   ├── diagnose.sh                # System diagnostics
│   └── setup-aws-provider.sh      # AWS provider setup wizard
│
├── config/                        # Configuration files
│   ├── kind-config.yaml           # Production cluster (3 nodes)
│   ├── kind-config-minimal.yaml   # Development cluster (1 node)
│   ├── provider-kubernetes.yaml   # Kubernetes provider
│   └── provider-rbac.yaml         # RBAC configuration
│
└── examples/                      # Example resources
    ├── example-namespace.yaml     # Namespace example
    ├── example-deployment.yaml    # Deployment example
    ├── example-service.yaml       # Service example
    └── aws/                       # AWS provider examples
        ├── README.md              # AWS examples guide
        ├── s3-bucket.yaml
        ├── vpc-network.yaml
        ├── ec2-instance.yaml
        ├── rds-database.yaml
        └── app-stack.yaml
```

## Usage

### Interactive Menu System

The `menu.sh` script provides a user-friendly interface for all operations:

```bash
./menu.sh
```

#### Menu Structure

1. **Cluster Management**
   - Create Cluster
   - Delete Cluster
   - Stop Cluster
   - Start Cluster
   - Restart Cluster
   - Cluster Info

2. **Crossplane Resources Management**
   - List All Resources
   - List Providers
   - List Provider Configs
   - List Managed Resources
   - Delete Specific Resource
   - Delete All Example Resources
   - Cleanup All Crossplane Resources

3. **Monitoring & Status**
   - Crossplane Status
   - Watch Crossplane Pods
   - View Crossplane Logs
   - Provider Status
   - Resource Status
   - Events

4. **Examples**
   - Apply All Examples
   - Apply Individual Examples
   - View Example Files
   - Create AWS Provider Example

5. **Documentation**
   - View README
   - Quick Start Guide
   - Provider Documentation
   - Troubleshooting Guide

### Command Line Operations

#### Cluster Management

```bash
# Create cluster
kind create cluster --name crossplane-cluster --config kind-config.yaml

# Delete cluster
kind delete cluster --name crossplane-cluster

# List clusters
kind get clusters

# Get cluster info
kubectl cluster-info --context kind-crossplane-cluster
```

#### Resource Management

```bash
# List all Crossplane resources
kubectl get providers
kubectl get providerconfigs
kubectl get object

# Apply examples
kubectl apply -f examples/

# Delete specific resource
kubectl delete object example-namespace

# Delete all examples
kubectl delete -f examples/
```

#### Monitoring

```bash
# Check Crossplane status
kubectl get pods -n crossplane-system

# View logs
kubectl logs -n crossplane-system -l app=crossplane

# Watch resources
kubectl get object -w

# View events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

## Examples

### Example 1: Managing Kubernetes Resources

The included examples demonstrate how to manage Kubernetes resources using Crossplane:

#### Namespace Example

```yaml
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
```

#### Deployment Example

```yaml
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
```

#### Service Example

```yaml
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
```

### Example 2: AWS Resources

This project includes comprehensive AWS examples in the `examples/aws/` directory:

- **S3 Bucket**: Create S3 buckets with versioning and public access blocking
- **VPC Network**: Complete VPC setup with public/private subnets and routing
- **EC2 Instance**: Web server with security groups
- **RDS Database**: PostgreSQL database with proper security configuration
- **Complete App Stack**: Full application infrastructure with all components

#### Quick Setup

Use the automated AWS provider setup script:

```bash
./setup-aws-provider.sh
```

This script will:
1. Install the AWS provider
2. Configure AWS credentials from your environment
3. Create a ProviderConfig
4. Verify the installation

#### Manual Setup

If you prefer manual setup:

```bash
# Create AWS credentials secret
kubectl create secret generic aws-secret \
  -n crossplane-system \
  --from-literal=credentials="[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY"

# Apply provider and configuration
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1.1.0
---
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: aws-provider
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-secret
      key: credentials
EOF
```

#### Using AWS Examples

```bash
# Create a simple S3 bucket
kubectl apply -f examples/aws/s3-bucket.yaml

# Create VPC and network infrastructure
kubectl apply -f examples/aws/vpc-network.yaml

# Create EC2 instance (requires VPC first)
kubectl apply -f examples/aws/ec2-instance.yaml

# Create RDS database (requires VPC first)
kubectl apply -f examples/aws/rds-database.yaml

# Create complete application stack
kubectl apply -f examples/aws/app-stack.yaml

# Check status
kubectl get managed
```

For detailed documentation, see [examples/aws/README.md](examples/aws/README.md).

### Example 3: Composite Resources

Create reusable infrastructure abstractions:

#### Define Composite Resource

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xwebapps.example.com
spec:
  group: example.com
  names:
    kind: XWebApp
    plural: xwebapps
  claimNames:
    kind: WebApp
    plural: webapps
  versions:
  - name: v1alpha1
    served: true
    referenceable: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              replicas:
                type: integer
                default: 1
              image:
                type: string
            required:
            - image
```

#### Define Composition

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: webapp-basic
spec:
  compositeTypeRef:
    apiVersion: example.com/v1alpha1
    kind: XWebApp
  resources:
  - name: namespace
    base:
      apiVersion: kubernetes.crossplane.io/v1alpha2
      kind: Object
      spec:
        forProvider:
          manifest:
            apiVersion: v1
            kind: Namespace
  - name: deployment
    base:
      apiVersion: kubernetes.crossplane.io/v1alpha2
      kind: Object
      spec:
        forProvider:
          manifest:
            apiVersion: apps/v1
            kind: Deployment
    patches:
    - fromFieldPath: spec.replicas
      toFieldPath: spec.forProvider.manifest.spec.replicas
    - fromFieldPath: spec.image
      toFieldPath: spec.forProvider.manifest.spec.template.spec.containers[0].image
```

#### Use Composite Resource

```yaml
apiVersion: example.com/v1alpha1
kind: WebApp
metadata:
  name: my-webapp
spec:
  replicas: 3
  image: nginx:1.21
```

## Architecture

### Crossplane Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Crossplane Control Plane                   │ │
│  │                                                          │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │ │
│  │  │  Crossplane  │  │     RBAC     │  │   Package    │ │ │
│  │  │     Core     │  │   Manager    │  │   Manager    │ │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘ │ │
│  │                                                          │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                     Providers                           │ │
│  │                                                          │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │ │
│  │  │   AWS    │  │  Azure   │  │   GCP    │  │  K8s   │ │ │
│  │  │ Provider │  │ Provider │  │ Provider │  │Provider│ │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └────────┘ │ │
│  │                                                          │ │
│  └────────────────────────────────────────────────────────┘ │
│                          │                                   │
└──────────────────────────┼───────────────────────────────────┘
                           │
                           ▼
        ┌─────────────────────────────────────┐
        │      External Infrastructure         │
        │                                      │
        │  ┌─────────┐  ┌─────────┐  ┌──────┐│
        │  │   AWS   │  │  Azure  │  │ GCP  ││
        │  │Resources│  │Resources│  │Res...││
        │  └─────────┘  └─────────┘  └──────┘│
        └─────────────────────────────────────┘
```

### Component Description

1. **Crossplane Core**: Main reconciliation engine
2. **RBAC Manager**: Manages permissions for providers
3. **Package Manager**: Installs and manages providers
4. **Providers**: Interface with external systems
5. **Managed Resources**: Kubernetes representations of external resources

## Providers

### Available Providers

Crossplane has a rich ecosystem of providers:

#### Major Cloud Providers

- **AWS**: xpkg.upbound.io/upbound/provider-aws
- **Azure**: xpkg.upbound.io/upbound/provider-azure
- **GCP**: xpkg.upbound.io/upbound/provider-gcp
- **Alibaba Cloud**: xpkg.upbound.io/upbound/provider-alibaba

#### Infrastructure Providers

- **Kubernetes**: xpkg.upbound.io/crossplane-contrib/provider-kubernetes
- **Helm**: xpkg.upbound.io/crossplane-contrib/provider-helm
- **Terraform**: xpkg.upbound.io/upbound/provider-terraform

#### Other Providers

- **Vault**: xpkg.upbound.io/crossplane-contrib/provider-vault
- **GitHub**: xpkg.upbound.io/coopnorge/provider-github
- **ArgoCD**: xpkg.upbound.io/crossplane-contrib/provider-argocd

### Provider Installation

Generic provider installation pattern:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-name
spec:
  package: xpkg.upbound.io/provider-org/provider-name:version
```

Check provider status:

```bash
kubectl get providers
kubectl describe provider provider-name
```

### Provider Configuration

Each provider requires a ProviderConfig for authentication:

```yaml
apiVersion: provider.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: provider-secret
      key: credentials
```

## Management Operations

### Cluster Operations

#### Start Cluster

```bash
# Using menu
./menu.sh
# Select: 1 -> 4

# Using Docker
docker start $(docker ps -aq --filter "name=crossplane-cluster")
```

#### Stop Cluster

```bash
# Using menu
./menu.sh
# Select: 1 -> 3

# Using Docker
docker stop $(docker ps -q --filter "name=crossplane-cluster")
```

#### Restart Cluster

```bash
# Using menu
./menu.sh
# Select: 1 -> 5

# Manual
docker restart $(docker ps -aq --filter "name=crossplane-cluster")
```

### Resource Operations

#### List Resources

```bash
# All Crossplane resources
kubectl get crossplane

# Specific resource types
kubectl get providers
kubectl get providerconfigs
kubectl get object
kubectl get compositions
kubectl get xrds
```

#### Describe Resources

```bash
# Get detailed information
kubectl describe object <resource-name>

# Get YAML representation
kubectl get object <resource-name> -o yaml
```

#### Delete Resources

```bash
# Delete specific resource
kubectl delete object <resource-name>

# Delete all resources from examples
kubectl delete -f examples/

# Delete all managed objects
kubectl delete object --all
```

### Monitoring Operations

#### Check Status

```bash
# Crossplane pods
kubectl get pods -n crossplane-system

# Provider status
kubectl get providers

# Resource status
kubectl get object -o wide
```

#### View Logs

```bash
# Crossplane core logs
kubectl logs -n crossplane-system -l app=crossplane -f

# Provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-kubernetes -f
```

#### Watch Resources

```bash
# Watch all objects
kubectl get object -w

# Watch events
kubectl get events -n crossplane-system -w
```

## Troubleshooting

### Common Issues

#### 1. Provider Not Healthy

**Symptoms:**
- Provider shows as "Unknown" or "Unhealthy"
- Resources not creating

**Diagnosis:**
```bash
kubectl get providers
kubectl describe provider provider-kubernetes
kubectl logs -n crossplane-system <provider-pod>
```

**Solutions:**
- Wait for provider to download and install (can take 2-5 minutes)
- Check provider pod logs for errors
- Verify provider package URL is correct
- Ensure provider has necessary RBAC permissions

#### 2. Resources Not Creating

**Symptoms:**
- Objects show as not ready
- Resources not appearing in cluster

**Diagnosis:**
```bash
kubectl get object
kubectl describe object <resource-name>
kubectl get events --all-namespaces
```

**Solutions:**
- Verify ProviderConfig is correctly configured
- Check provider is healthy
- Ensure referenced namespace exists
- Verify RBAC permissions
- Check provider logs for authentication errors

#### 3. Cluster Won't Start

**Symptoms:**
- Cluster containers not running
- kubectl commands timeout

**Diagnosis:**
```bash
kind get clusters
docker ps -a | grep crossplane
docker logs crossplane-cluster-control-plane
```

**Solutions:**
- Check Docker is running
- Verify Docker has sufficient resources
- Delete and recreate cluster
- Check for port conflicts

#### 4. Permission Errors

**Symptoms:**
- "Forbidden" errors in logs
- Resources fail to create with permission denied

**Diagnosis:**
```bash
kubectl get sa -n crossplane-system
kubectl get clusterrolebinding provider-kubernetes
```

**Solutions:**
- Verify ServiceAccount exists
- Check ClusterRoleBinding is correct
- Ensure provider has necessary permissions
- Review provider configuration

#### 5. Provider Installation Timeout

**Symptoms:**
- Provider stays in "Installing" state
- Provider pod not starting

**Diagnosis:**
```bash
kubectl get pods -n crossplane-system
kubectl describe pod <provider-pod> -n crossplane-system
```

**Solutions:**
- Check internet connectivity
- Verify provider package URL
- Check Docker pull rate limits
- Increase timeout and wait longer

### Debug Commands

```bash
# Get all resources in crossplane-system namespace
kubectl get all -n crossplane-system

# Get provider revision (shows download progress)
kubectl get providerrevision

# Get detailed provider status
kubectl get providers -o yaml

# Check resource conditions
kubectl get object <name> -o jsonpath='{.status.conditions}'

# Get events for specific resource
kubectl describe object <name>
```

### Logs Collection

```bash
# Collect all Crossplane logs
kubectl logs -n crossplane-system -l app=crossplane > crossplane-core.log
kubectl logs -n crossplane-system -l app=crossplane-rbac-manager > rbac-manager.log

# Collect provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-kubernetes > provider-kubernetes.log

# Collect events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' > events.log
```

## Best Practices

### 1. Resource Organization

- Use meaningful resource names
- Add labels and annotations for tracking
- Group related resources in same namespace
- Use compositions for complex infrastructure

### 2. Version Control

- Store all manifests in Git
- Use GitOps workflow (ArgoCD, Flux)
- Tag provider versions explicitly
- Document infrastructure changes

### 3. Security

- Use separate ProviderConfigs per environment
- Store credentials in secrets
- Apply least privilege RBAC
- Regularly rotate credentials
- Use namespaces for isolation

### 4. Monitoring

- Monitor provider health
- Set up alerts for resource failures
- Track reconciliation times
- Monitor resource drift

### 5. Testing

- Test in development environment first
- Validate compositions before production
- Use dry-run for changes
- Keep example configurations

### 6. Performance

- Limit concurrent reconciliations
- Use resource quotas
- Monitor etcd size
- Clean up unused resources

### 7. Disaster Recovery

- Backup etcd regularly
- Document recovery procedures
- Test restore process
- Keep provider versions documented

## References

### Official Documentation

- [Crossplane Documentation](https://docs.crossplane.io/)
- [Crossplane GitHub](https://github.com/crossplane/crossplane)
- [Upbound Marketplace](https://marketplace.upbound.io/)
- [Crossplane Slack](https://slack.crossplane.io/)

### Provider Documentation

- [Kubernetes Provider](https://marketplace.upbound.io/providers/crossplane-contrib/provider-kubernetes)
- [AWS Provider](https://marketplace.upbound.io/providers/upbound/provider-aws)
- [Azure Provider](https://marketplace.upbound.io/providers/upbound/provider-azure)
- [GCP Provider](https://marketplace.upbound.io/providers/upbound/provider-gcp)

### Learning Resources

- [Crossplane Concepts](https://docs.crossplane.io/latest/concepts/)
- [Getting Started Guide](https://docs.crossplane.io/latest/getting-started/)
- [Composition Guide](https://docs.crossplane.io/latest/concepts/compositions/)
- [Provider Development](https://docs.crossplane.io/latest/contributing/provider-development-guide/)

### Community Resources

- [Crossplane Blog](https://blog.crossplane.io/)
- [CNCF Crossplane Project](https://www.cncf.io/projects/crossplane/)
- [YouTube Channel](https://www.youtube.com/c/crossplane-io)
- [Community Meetings](https://github.com/crossplane/crossplane#get-involved)

### Tools and Utilities

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [Helm Documentation](https://helm.sh/docs/)
- [Crossplane CLI](https://docs.crossplane.io/latest/cli/)

### Related Projects

- [ArgoCD](https://argoproj.github.io/cd/) - GitOps continuous delivery
- [Flux](https://fluxcd.io/) - GitOps toolkit
- [Terraform](https://www.terraform.io/) - Infrastructure as Code
- [Pulumi](https://www.pulumi.com/) - Infrastructure as Code

## License

This project is provided as-is for educational and demonstration purposes.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Support

For issues and questions:
- Check the troubleshooting section
- Review Crossplane documentation
- Join Crossplane Slack community
- Open an issue in the project repository
