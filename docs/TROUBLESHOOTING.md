# Crossplane Troubleshooting Guide

## Table of Contents
1. [Provider Issues](#provider-issues)
2. [Resource Creation Issues](#resource-creation-issues)
3. [Cluster Issues](#cluster-issues)
4. [Authentication Issues](#authentication-issues)
5. [Performance Issues](#performance-issues)
6. [Network Issues](#network-issues)
7. [Debug Commands Reference](#debug-commands-reference)

## Provider Issues

### Provider Stuck in "Installing" State

**Symptoms:**
```bash
$ kubectl get providers
NAME                  INSTALLED   HEALTHY   PACKAGE
provider-kubernetes   Unknown     Unknown   xpkg.upbound.io/...
```

**Diagnosis:**
```bash
# Check provider revision
kubectl get providerrevision

# Check provider pod
kubectl get pods -n crossplane-system

# Check pod status
kubectl describe pod -n crossplane-system <provider-pod-name>
```

**Common Causes & Solutions:**

1. **Image pull issues**
   ```bash
   # Check events
   kubectl get events -n crossplane-system --sort-by='.lastTimestamp'
   
   # Solution: Wait or check internet connectivity
   # Docker Hub rate limits may apply
   ```

2. **Insufficient resources**
   ```bash
   # Check node resources
   kubectl describe nodes
   
   # Solution: Increase Docker resources or delete other pods
   ```

3. **Package URL incorrect**
   ```bash
   # Check provider spec
   kubectl get provider provider-kubernetes -o yaml
   
   # Solution: Verify package URL and version
   ```

### Provider Not Healthy

**Symptoms:**
```bash
$ kubectl get providers
NAME                  INSTALLED   HEALTHY   PACKAGE
provider-kubernetes   True        False     xpkg.upbound.io/...
```

**Diagnosis:**
```bash
# Describe provider
kubectl describe provider provider-kubernetes

# Check provider pod logs
POD=$(kubectl get pods -n crossplane-system -l pkg.crossplane.io/provider=provider-kubernetes -o name)
kubectl logs -n crossplane-system $POD

# Check provider conditions
kubectl get provider provider-kubernetes -o jsonpath='{.status.conditions}'
```

**Common Causes & Solutions:**

1. **Missing RBAC permissions**
   ```bash
   # Check ServiceAccount
   kubectl get sa provider-kubernetes -n crossplane-system
   
   # Check ClusterRoleBinding
   kubectl get clusterrolebinding provider-kubernetes
   
   # Solution: Reapply provider configuration
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
   ```

2. **ProviderConfig missing or misconfigured**
   ```bash
   # Check provider configs
   kubectl get providerconfigs
   
   # Solution: Create or fix provider config
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

3. **Provider crash loop**
   ```bash
   # Check pod restarts
   kubectl get pods -n crossplane-system
   
   # Check logs for errors
   kubectl logs -n crossplane-system $POD --previous
   
   # Solution: Check logs for specific error and fix configuration
   ```

## Resource Creation Issues

### Resources Not Syncing

**Symptoms:**
- Resources show as not ready
- No error messages in resource status

**Diagnosis:**
```bash
# Check resource status
kubectl get object <resource-name> -o yaml

# Check conditions
kubectl get object <resource-name> -o jsonpath='{.status.conditions}'

# Describe resource
kubectl describe object <resource-name>
```

**Common Causes & Solutions:**

1. **Wrong ProviderConfig reference**
   ```bash
   # Check ProviderConfig name in resource
   kubectl get object <resource-name> -o jsonpath='{.spec.providerConfigRef.name}'
   
   # List available ProviderConfigs
   kubectl get providerconfigs
   
   # Solution: Update resource with correct providerConfigRef
   ```

2. **Invalid manifest**
   ```bash
   # Check the manifest in the Object spec
   kubectl get object <resource-name> -o jsonpath='{.spec.forProvider.manifest}'
   
   # Solution: Validate YAML syntax and Kubernetes API version
   ```

3. **Namespace doesn't exist**
   ```bash
   # Check if target namespace exists
   kubectl get namespace <namespace-name>
   
   # Solution: Create namespace first or remove namespace from manifest
   ```

### Resources Failing with Errors

**Symptoms:**
```bash
$ kubectl get object
NAME                 SYNCED   READY   AGE
example-deployment   False    False   5m
```

**Diagnosis:**
```bash
# Get detailed status
kubectl describe object example-deployment

# Check events
kubectl get events --all-namespaces | grep example-deployment

# Check provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-kubernetes
```

**Common Causes & Solutions:**

1. **Permission denied errors**
   ```bash
   # Verify provider ServiceAccount permissions
   kubectl auth can-i create deployment --as=system:serviceaccount:crossplane-system:provider-kubernetes
   
   # Solution: Grant necessary permissions or use cluster-admin
   ```

2. **Resource conflicts**
   ```bash
   # Check if resource already exists
   kubectl get deployment <name> -n <namespace>
   
   # Solution: Delete existing resource or use different name
   ```

3. **Validation errors**
   ```bash
   # Check manifest syntax
   kubectl get object <name> -o jsonpath='{.spec.forProvider.manifest}' | kubectl apply --dry-run=client -f -
   
   # Solution: Fix manifest according to Kubernetes API requirements
   ```

## Cluster Issues

### Cluster Won't Start

**Symptoms:**
- kubectl commands timeout
- Kind cluster exists but not accessible

**Diagnosis:**
```bash
# Check cluster status
kind get clusters

# Check Docker containers
docker ps -a | grep crossplane-cluster

# Check container logs
docker logs crossplane-cluster-control-plane
```

**Common Causes & Solutions:**

1. **Docker not running**
   ```bash
   # Check Docker
   docker ps
   
   # Solution: Start Docker Desktop
   ```

2. **Containers stopped**
   ```bash
   # List stopped containers
   docker ps -a --filter "name=crossplane-cluster"
   
   # Solution: Start containers
   docker start $(docker ps -aq --filter "name=crossplane-cluster")
   ```

3. **Port conflicts**
   ```bash
   # Check port usage
   lsof -i :80 -i :443
   
   # Solution: Stop conflicting services or change ports in kind-config.yaml
   ```

4. **Corrupted cluster state**
   ```bash
   # Solution: Delete and recreate
   kind delete cluster --name crossplane-cluster
   ./setup.sh
   ```

### Cluster Out of Resources

**Symptoms:**
- Pods pending
- "Insufficient memory/cpu" errors

**Diagnosis:**
```bash
# Check node resources
kubectl describe nodes

# Check pod resource requests
kubectl describe pod <pod-name> -n crossplane-system
```

**Solutions:**

1. **Increase Docker resources**
   - Docker Desktop -> Preferences -> Resources
   - Increase CPUs and Memory

2. **Delete unused resources**
   ```bash
   # Delete old pods
   kubectl delete pod <old-pod> -n crossplane-system
   
   # Clean up completed jobs
   kubectl delete jobs --field-selector status.successful=1
   ```

## Authentication Issues

### AWS Provider Authentication Fails

**Diagnosis:**
```bash
# Check secret exists
kubectl get secret aws-secret -n crossplane-system

# Check secret content
kubectl get secret aws-secret -n crossplane-system -o jsonpath='{.data.creds}' | base64 -d

# Check ProviderConfig
kubectl get providerconfig default -o yaml
```

**Solutions:**

1. **Recreate credentials secret**
   ```bash
   # Delete old secret
   kubectl delete secret aws-secret -n crossplane-system
   
   # Create new secret with correct format
   cat > aws-credentials.txt <<EOF
   [default]
   aws_access_key_id = YOUR_KEY
   aws_secret_access_key = YOUR_SECRET
   EOF
   
   kubectl create secret generic aws-secret \
     -n crossplane-system \
     --from-file=creds=./aws-credentials.txt
   
   # Clean up
   rm aws-credentials.txt
   ```

2. **Verify credentials format**
   - Must be in AWS credentials file format
   - Must include [default] profile

### Kubernetes Provider Can't Access Cluster

**Diagnosis:**
```bash
# Check provider ServiceAccount
kubectl get sa provider-kubernetes -n crossplane-system

# Check RBAC
kubectl get clusterrolebinding provider-kubernetes

# Check provider config
kubectl get providerconfig kubernetes-provider -o yaml
```

**Solutions:**
```bash
# Recreate ServiceAccount and RBAC
kubectl delete sa provider-kubernetes -n crossplane-system
kubectl delete clusterrolebinding provider-kubernetes

# Run setup script section
./setup.sh
```

## Performance Issues

### Slow Reconciliation

**Symptoms:**
- Resources take long time to create
- Delayed status updates

**Diagnosis:**
```bash
# Check Crossplane logs
kubectl logs -n crossplane-system -l app=crossplane | grep -i "reconcil"

# Check resource conditions timestamp
kubectl get object <name> -o jsonpath='{.status.conditions[*].lastTransitionTime}'
```

**Solutions:**

1. **Increase reconciliation workers**
   ```bash
   # Edit Crossplane deployment
   kubectl edit deployment crossplane -n crossplane-system
   
   # Add args:
   # - --max-reconcile-rate=10
   ```

2. **Check network connectivity**
   ```bash
   # Test from Crossplane pod
   kubectl exec -n crossplane-system <crossplane-pod> -- curl -I https://kubernetes.default.svc
   ```

### High Memory Usage

**Diagnosis:**
```bash
# Check pod memory
kubectl top pods -n crossplane-system

# Check metrics
kubectl describe node
```

**Solutions:**

1. **Increase pod memory limits**
   ```bash
   kubectl edit deployment crossplane -n crossplane-system
   # Increase resources.limits.memory
   ```

2. **Reduce number of resources**
   ```bash
   # Clean up old resources
   kubectl delete object --field-selector status.conditions[].status=False
   ```

## Network Issues

### Can't Pull Provider Images

**Symptoms:**
- ImagePullBackOff errors
- Provider stuck in Installing

**Diagnosis:**
```bash
# Check pod events
kubectl describe pod <provider-pod> -n crossplane-system

# Test image pull
docker pull xpkg.upbound.io/crossplane-contrib/provider-kubernetes:v0.13.0
```

**Solutions:**

1. **Docker Hub rate limits**
   ```bash
   # Use authenticated Docker Hub account
   kubectl create secret docker-registry dockerhub \
     --docker-server=docker.io \
     --docker-username=YOUR_USERNAME \
     --docker-password=YOUR_PASSWORD \
     -n crossplane-system
   ```

2. **Proxy configuration**
   ```bash
   # Configure Docker proxy
   # Add to ~/.docker/config.json
   {
     "proxies": {
       "default": {
         "httpProxy": "http://proxy.example.com:8080",
         "httpsProxy": "http://proxy.example.com:8080"
       }
     }
   }
   ```

### Resources Can't Connect to Cloud APIs

**Diagnosis:**
```bash
# Check provider logs
kubectl logs -n crossplane-system <provider-pod>

# Check network policies
kubectl get networkpolicies -A
```

**Solutions:**

1. **Verify cloud credentials**
   ```bash
   # Test credentials manually
   aws sts get-caller-identity  # for AWS
   az account show              # for Azure
   gcloud auth list            # for GCP
   ```

2. **Check firewall rules**
   - Ensure outbound HTTPS allowed
   - Allow access to cloud provider APIs

## Debug Commands Reference

### Cluster Information
```bash
# Cluster info
kubectl cluster-info
kubectl get nodes
kubectl version

# Kind clusters
kind get clusters
kind get kubeconfig --name crossplane-cluster

# Docker containers
docker ps -a | grep crossplane
docker logs crossplane-cluster-control-plane
```

### Crossplane Status
```bash
# Pods
kubectl get pods -n crossplane-system
kubectl describe pod <pod-name> -n crossplane-system

# Deployments
kubectl get deployments -n crossplane-system
kubectl describe deployment crossplane -n crossplane-system

# Version
kubectl get deployment crossplane -n crossplane-system -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Provider Status
```bash
# List providers
kubectl get providers
kubectl get providers -o wide

# Describe provider
kubectl describe provider <provider-name>

# Provider revision
kubectl get providerrevision

# Provider pods
kubectl get pods -n crossplane-system -l pkg.crossplane.io/provider=<provider-name>

# Provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=<provider-name> -f
```

### Resource Status
```bash
# List resources
kubectl get object
kubectl get object -o wide

# Describe resource
kubectl describe object <resource-name>

# Get resource YAML
kubectl get object <resource-name> -o yaml

# Check conditions
kubectl get object <resource-name> -o jsonpath='{.status.conditions}'

# Watch resources
kubectl get object -w
```

### Events
```bash
# All events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Specific namespace
kubectl get events -n crossplane-system --sort-by='.lastTimestamp'

# Watch events
kubectl get events -n crossplane-system -w

# Events for specific resource
kubectl describe object <resource-name>
```

### Logs Collection
```bash
# Crossplane core
kubectl logs -n crossplane-system -l app=crossplane > crossplane.log
kubectl logs -n crossplane-system -l app=crossplane --previous > crossplane-previous.log

# RBAC manager
kubectl logs -n crossplane-system -l app=crossplane-rbac-manager > rbac-manager.log

# Provider
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-kubernetes > provider.log

# All logs
kubectl logs -n crossplane-system --all-containers=true > all-logs.log
```

### Configuration
```bash
# ProviderConfigs
kubectl get providerconfigs
kubectl get providerconfigs -o yaml

# ServiceAccounts
kubectl get sa -n crossplane-system

# RBAC
kubectl get clusterrolebinding | grep crossplane
kubectl get clusterrole | grep crossplane

# Secrets
kubectl get secrets -n crossplane-system
```

### Testing
```bash
# Dry run resource
kubectl apply -f resource.yaml --dry-run=client

# Validate manifest
kubectl apply -f resource.yaml --validate=true --dry-run=server

# Test permissions
kubectl auth can-i create deployment --as=system:serviceaccount:crossplane-system:provider-kubernetes
```

## Getting Help

If issues persist:

1. **Collect diagnostic information**
   ```bash
   # Run status script
   ./status.sh > status-output.txt
   
   # Collect logs
   kubectl logs -n crossplane-system --all-containers=true > all-logs.txt
   
   # Get resource dumps
   kubectl get all -n crossplane-system -o yaml > resources.yaml
   ```

2. **Check documentation**
   - Crossplane docs: https://docs.crossplane.io/
   - Provider docs: https://marketplace.upbound.io/

3. **Community support**
   - Slack: https://slack.crossplane.io/
   - GitHub Issues: https://github.com/crossplane/crossplane/issues
   - Stack Overflow: Tag with `crossplane`

4. **Include in bug reports**
   - Crossplane version
   - Provider version
   - Kubernetes version
   - Error messages and logs
   - Steps to reproduce
