# Crossplane Quick Reference Cheat Sheet

## Quick Start Commands

```bash
# Setup everything
./setup.sh

# Interactive menu
./menu.sh

# Check status
./status.sh

# Cleanup
./cleanup.sh
```

## Makefile Commands

```bash
make help              # Show all available commands
make setup             # Create cluster and install Crossplane
make status            # Show cluster status
make menu              # Open interactive menu
make start             # Start cluster
make stop              # Stop cluster
make restart           # Restart cluster
make delete            # Delete cluster
make apply-examples    # Apply example resources
make clean-examples    # Delete example resources
make list-resources    # List all resources
make logs              # View Crossplane logs
make watch             # Watch resources
```

## Kind Cluster Commands

```bash
# Create cluster
kind create cluster --name crossplane-cluster --config kind-config.yaml

# List clusters
kind get clusters

# Delete cluster
kind delete cluster --name crossplane-cluster

# Get kubeconfig
kind get kubeconfig --name crossplane-cluster

# Load image into cluster
kind load docker-image <image-name> --name crossplane-cluster
```

## Docker Commands for Cluster

```bash
# List cluster containers
docker ps --filter "name=crossplane-cluster"

# Stop cluster
docker stop $(docker ps -q --filter "name=crossplane-cluster")

# Start cluster
docker start $(docker ps -aq --filter "name=crossplane-cluster")

# View container logs
docker logs crossplane-cluster-control-plane

# Execute in container
docker exec -it crossplane-cluster-control-plane bash
```

## Crossplane Installation

```bash
# Add Helm repo
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Install Crossplane
helm install crossplane \
  --namespace crossplane-system \
  --create-namespace \
  crossplane-stable/crossplane

# Upgrade Crossplane
helm upgrade crossplane \
  --namespace crossplane-system \
  crossplane-stable/crossplane

# Uninstall Crossplane
helm uninstall crossplane --namespace crossplane-system
```

## Provider Management

```bash
# Install provider
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-kubernetes:v0.13.0
EOF

# List providers
kubectl get providers

# Describe provider
kubectl describe provider provider-kubernetes

# Delete provider
kubectl delete provider provider-kubernetes

# Check provider health
kubectl get provider provider-kubernetes -o jsonpath='{.status.conditions[?(@.type=="Healthy")].status}'
```

## Common Providers

```bash
# Kubernetes Provider
package: xpkg.upbound.io/crossplane-contrib/provider-kubernetes:v0.13.0

# AWS Provider
package: xpkg.upbound.io/upbound/provider-aws:v0.40.0

# Azure Provider
package: xpkg.upbound.io/upbound/provider-azure:v0.36.0

# GCP Provider
package: xpkg.upbound.io/upbound/provider-gcp:v0.36.0

# Helm Provider
package: xpkg.upbound.io/crossplane-contrib/provider-helm:v0.15.0

# Terraform Provider
package: xpkg.upbound.io/upbound/provider-terraform:v0.7.0
```

## ProviderConfig

```bash
# Kubernetes ProviderConfig (in-cluster)
kubectl apply -f - <<EOF
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kubernetes-provider
spec:
  credentials:
    source: InjectedIdentity
EOF

# AWS ProviderConfig
kubectl apply -f - <<EOF
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

# List ProviderConfigs
kubectl get providerconfigs

# Describe ProviderConfig
kubectl describe providerconfig kubernetes-provider
```

## Resource Management

```bash
# Apply resource
kubectl apply -f resource.yaml

# List all Crossplane objects
kubectl get object

# List all objects in all namespaces
kubectl get object -A

# Describe object
kubectl describe object <name>

# Get object YAML
kubectl get object <name> -o yaml

# Delete object
kubectl delete object <name>

# Delete all objects
kubectl delete object --all

# Watch objects
kubectl get object -w
```

## Resource Status

```bash
# Check if resource is ready
kubectl get object <name> -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'

# Check if resource is synced
kubectl get object <name> -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}'

# Get all conditions
kubectl get object <name> -o jsonpath='{.status.conditions}'

# Get resource age
kubectl get object <name> -o jsonpath='{.metadata.creationTimestamp}'
```

## Compositions

```bash
# List CompositeResourceDefinitions (XRDs)
kubectl get xrds

# List Compositions
kubectl get compositions

# Describe Composition
kubectl describe composition <name>

# List Composite Resources
kubectl get composite

# List Claims
kubectl get claim -A
```

## Monitoring and Debugging

```bash
# Check Crossplane pods
kubectl get pods -n crossplane-system

# Watch Crossplane pods
kubectl get pods -n crossplane-system -w

# Crossplane core logs
kubectl logs -n crossplane-system -l app=crossplane -f

# RBAC manager logs
kubectl logs -n crossplane-system -l app=crossplane-rbac-manager -f

# Provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-kubernetes -f

# All Crossplane logs
kubectl logs -n crossplane-system --all-containers=true -f
```

## Events

```bash
# All events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Crossplane system events
kubectl get events -n crossplane-system --sort-by='.lastTimestamp'

# Events for specific resource
kubectl describe object <name>

# Watch events
kubectl get events -n crossplane-system -w

# Filter warning events
kubectl get events --field-selector type=Warning -A
```

## Secret Management

```bash
# Create AWS credentials secret
kubectl create secret generic aws-secret \
  -n crossplane-system \
  --from-file=creds=./aws-credentials.txt

# Create generic secret
kubectl create secret generic my-secret \
  -n crossplane-system \
  --from-literal=key=value

# Get secret
kubectl get secret aws-secret -n crossplane-system

# Decode secret
kubectl get secret aws-secret -n crossplane-system -o jsonpath='{.data.creds}' | base64 -d

# Delete secret
kubectl delete secret aws-secret -n crossplane-system
```

## ServiceAccount and RBAC

```bash
# Create ServiceAccount
kubectl create sa provider-kubernetes -n crossplane-system

# Create ClusterRoleBinding
kubectl create clusterrolebinding provider-kubernetes \
  --clusterrole=cluster-admin \
  --serviceaccount=crossplane-system:provider-kubernetes

# List ServiceAccounts
kubectl get sa -n crossplane-system

# List ClusterRoleBindings
kubectl get clusterrolebinding | grep crossplane

# Check permissions
kubectl auth can-i create deployment --as=system:serviceaccount:crossplane-system:provider-kubernetes
```

## Useful kubectl Commands

```bash
# Get all Crossplane resources
kubectl get crossplane

# Get resources with custom columns
kubectl get object -o custom-columns=NAME:.metadata.name,SYNCED:.status.conditions[0].status,READY:.status.conditions[1].status

# Get resources by label
kubectl get object -l app=nginx

# Sort by creation time
kubectl get object --sort-by=.metadata.creationTimestamp

# Output as JSON
kubectl get object <name> -o json

# Get specific field
kubectl get object <name> -o jsonpath='{.spec.providerConfigRef.name}'

# Watch with timestamps
kubectl get object -w --show-labels
```

## Troubleshooting Commands

```bash
# Verify Crossplane installation
kubectl get all -n crossplane-system

# Check provider health
kubectl get providers -o wide

# Check resource sync status
kubectl get object -o wide

# Describe failing resource
kubectl describe object <name>

# Get provider pod name
kubectl get pods -n crossplane-system -l pkg.crossplane.io/provider=provider-kubernetes

# Check provider container status
kubectl get pods -n crossplane-system -o jsonpath='{.items[*].status.containerStatuses[*]}'

# Test manifest validity
kubectl apply -f manifest.yaml --dry-run=client

# Check API resources
kubectl api-resources | grep crossplane
```

## Example Resources

```bash
# Create namespace via Crossplane
kubectl apply -f - <<EOF
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
        name: my-namespace
  providerConfigRef:
    name: kubernetes-provider
EOF

# Create deployment via Crossplane
kubectl apply -f - <<EOF
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
        name: nginx
        namespace: default
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
              image: nginx:latest
  providerConfigRef:
    name: kubernetes-provider
EOF
```

## Resource Cleanup

```bash
# Delete all objects
kubectl delete object --all

# Delete all in specific namespace
kubectl delete object -n my-namespace --all

# Delete resources from directory
kubectl delete -f examples/

# Delete with force
kubectl delete object <name> --force --grace-period=0

# Cleanup finalizers (use carefully)
kubectl patch object <name> -p '{"metadata":{"finalizers":[]}}' --type=merge
```

## Performance Tuning

```bash
# Increase reconciliation rate
kubectl edit deployment crossplane -n crossplane-system
# Add: --max-reconcile-rate=10

# Check resource usage
kubectl top pods -n crossplane-system

# Check node resources
kubectl top nodes

# Describe node resources
kubectl describe nodes
```

## Backup and Restore

```bash
# Backup all Crossplane resources
kubectl get providers -o yaml > providers-backup.yaml
kubectl get providerconfigs -o yaml > providerconfigs-backup.yaml
kubectl get object -o yaml > objects-backup.yaml

# Restore from backup
kubectl apply -f providers-backup.yaml
kubectl apply -f providerconfigs-backup.yaml
kubectl apply -f objects-backup.yaml

# Backup namespace
kubectl get all -n crossplane-system -o yaml > crossplane-system-backup.yaml
```

## Version Information

```bash
# Crossplane version
kubectl get deployment crossplane -n crossplane-system -o jsonpath='{.spec.template.spec.containers[0].image}'

# Provider version
kubectl get provider provider-kubernetes -o jsonpath='{.spec.package}'

# Kubernetes version
kubectl version --short

# Kind version
kind version
```

## Quick Tips

1. **Always check provider health first**: `kubectl get providers`
2. **Use describe for detailed errors**: `kubectl describe object <name>`
3. **Watch resources during creation**: `kubectl get object -w`
4. **Check logs when things fail**: `kubectl logs -n crossplane-system -l app=crossplane`
5. **Validate manifests before applying**: `kubectl apply --dry-run=client -f file.yaml`
6. **Use labels for organization**: Add meaningful labels to all resources
7. **Keep provider versions explicit**: Don't use `:latest` tag
8. **Test in dev first**: Always test changes in development before production
9. **Monitor reconciliation**: Watch for slow or failing reconciliations
10. **Clean up unused resources**: Regularly delete old/unused resources

## Common Issues Quick Fix

```bash
# Provider not healthy
kubectl delete provider <name>
kubectl apply -f provider.yaml

# Resource stuck
kubectl delete object <name> --force --grace-period=0

# Cluster not responding
docker restart $(docker ps -aq --filter "name=crossplane-cluster")

# Reset everything
kind delete cluster --name crossplane-cluster
./setup.sh
```

## URLs and Links

- Crossplane Docs: https://docs.crossplane.io
- Provider Marketplace: https://marketplace.upbound.io
- Crossplane Slack: https://slack.crossplane.io
- GitHub: https://github.com/crossplane/crossplane
- Kind Docs: https://kind.sigs.k8s.io
