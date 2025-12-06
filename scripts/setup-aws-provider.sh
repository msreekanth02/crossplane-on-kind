#!/bin/bash

# AWS Provider Setup Script
# This script helps setup AWS provider for Crossplane

set -e

NAMESPACE="crossplane-system"

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

print_header() {
    echo
    print_message "$BLUE" "=========================================="
    print_message "$BLUE" "  AWS Provider Setup for Crossplane"
    print_message "$BLUE" "=========================================="
    echo
}

print_header

print_message "$YELLOW" "This script will help you set up AWS provider for Crossplane."
print_message "$YELLOW" "You will need AWS credentials (Access Key ID and Secret Access Key)."
echo

read -p "Do you want to continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_message "$YELLOW" "Setup cancelled."
    exit 0
fi

# Check if cluster is running
if ! kubectl cluster-info &>/dev/null; then
    print_message "$RED" "Cluster is not running or kubectl cannot connect!"
    print_message "$YELLOW" "Please start the cluster first: ./menu.sh -> Cluster Management -> Start Cluster"
    exit 1
fi

# Create examples/aws directory
print_message "$BLUE" "Creating AWS examples directory..."
mkdir -p examples/aws

# Install AWS Provider
print_message "$BLUE" "Creating AWS Provider manifest..."
cat > examples/aws/provider-aws.yaml <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws
spec:
  package: xpkg.upbound.io/upbound/provider-aws:v0.40.0
EOF

print_message "$BLUE" "Installing AWS Provider..."
kubectl apply -f examples/aws/provider-aws.yaml

print_message "$YELLOW" "Waiting for provider to install (this may take 2-5 minutes)..."
echo "You can check progress with: kubectl get providers"
echo

# Get AWS credentials
print_message "$BLUE" "AWS Credentials Setup"
echo

read -p "Enter your AWS Access Key ID: " aws_access_key
read -s -p "Enter your AWS Secret Access Key: " aws_secret_key
echo
echo

read -p "Enter AWS region (default: us-east-1): " aws_region
aws_region=${aws_region:-us-east-1}

# Create credentials file
print_message "$BLUE" "Creating credentials file..."
cat > /tmp/aws-credentials.txt <<EOF
[default]
aws_access_key_id = ${aws_access_key}
aws_secret_access_key = ${aws_secret_key}
EOF

# Create secret
print_message "$BLUE" "Creating Kubernetes secret..."
kubectl create secret generic aws-secret \
  -n ${NAMESPACE} \
  --from-file=creds=/tmp/aws-credentials.txt \
  --dry-run=client -o yaml | kubectl apply -f -

# Clean up credentials file
rm -f /tmp/aws-credentials.txt
print_message "$GREEN" "Credentials secret created successfully!"

# Create ProviderConfig
print_message "$BLUE" "Creating ProviderConfig..."
cat > examples/aws/provider-config-aws.yaml <<EOF
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: ${NAMESPACE}
      name: aws-secret
      key: creds
EOF

kubectl apply -f examples/aws/provider-config-aws.yaml
print_message "$GREEN" "ProviderConfig created successfully!"

# Create example S3 bucket
print_message "$BLUE" "Creating example S3 bucket manifest..."
bucket_name="crossplane-example-bucket-$(date +%s)"
cat > examples/aws/example-s3-bucket.yaml <<EOF
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: ${bucket_name}
spec:
  forProvider:
    region: ${aws_region}
  providerConfigRef:
    name: default
EOF

print_message "$GREEN" "Example S3 bucket manifest created!"

# Create example VPC
print_message "$BLUE" "Creating example VPC manifest..."
cat > examples/aws/example-vpc.yaml <<EOF
apiVersion: ec2.aws.upbound.io/v1beta1
kind: VPC
metadata:
  name: crossplane-example-vpc
spec:
  forProvider:
    region: ${aws_region}
    cidrBlock: 10.0.0.0/16
    enableDnsHostnames: true
    enableDnsSupport: true
    tags:
      Name: crossplane-example-vpc
      ManagedBy: crossplane
  providerConfigRef:
    name: default
EOF

print_message "$GREEN" "Example VPC manifest created!"

# Create example subnet
print_message "$BLUE" "Creating example subnet manifest..."
cat > examples/aws/example-subnet.yaml <<EOF
apiVersion: ec2.aws.upbound.io/v1beta1
kind: Subnet
metadata:
  name: crossplane-example-subnet
spec:
  forProvider:
    region: ${aws_region}
    availabilityZone: ${aws_region}a
    cidrBlock: 10.0.1.0/24
    vpcIdSelector:
      matchLabels:
        name: crossplane-example-vpc
    tags:
      Name: crossplane-example-subnet
      ManagedBy: crossplane
  providerConfigRef:
    name: default
EOF

print_message "$GREEN" "Example subnet manifest created!"

# Create README for AWS examples
print_message "$BLUE" "Creating AWS examples README..."
cat > examples/aws/README.md <<EOF
# AWS Provider Examples

This directory contains example resources for AWS provider.

## Prerequisites

1. AWS provider installed
2. AWS credentials configured
3. ProviderConfig created

## Examples

### S3 Bucket

\`\`\`bash
kubectl apply -f example-s3-bucket.yaml
kubectl get bucket
\`\`\`

### VPC

\`\`\`bash
kubectl apply -f example-vpc.yaml
kubectl get vpc
\`\`\`

### Subnet

Note: This requires the VPC to be created first.

\`\`\`bash
kubectl apply -f example-subnet.yaml
kubectl get subnet
\`\`\`

## Verify Resources

\`\`\`bash
# Check all AWS resources
kubectl get managed

# Check specific resource
kubectl describe bucket ${bucket_name}

# View in AWS Console
# Resources will be visible in your AWS account
\`\`\`

## Cleanup

\`\`\`bash
# Delete all AWS resources
kubectl delete -f .

# Or individually
kubectl delete -f example-s3-bucket.yaml
kubectl delete -f example-subnet.yaml
kubectl delete -f example-vpc.yaml
\`\`\`

## Important Notes

1. **Costs**: These resources may incur AWS charges
2. **Deletion**: Always delete resources when done
3. **Region**: Resources are created in ${aws_region}
4. **Naming**: Bucket names must be globally unique
5. **Permissions**: Your AWS credentials must have appropriate permissions

## Monitoring

\`\`\`bash
# Watch resource creation
kubectl get bucket -w

# Check events
kubectl describe bucket ${bucket_name}

# View provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-aws
\`\`\`
EOF

print_message "$GREEN" "AWS examples README created!"

# Summary
echo
print_message "$GREEN" "=========================================="
print_message "$GREEN" "AWS Provider Setup Complete!"
print_message "$GREEN" "=========================================="
echo
print_message "$BLUE" "Next Steps:"
print_message "$YELLOW" "1. Wait for provider to become healthy:"
print_message "$BLUE" "   kubectl get providers"
echo
print_message "$YELLOW" "2. Apply example resources:"
print_message "$BLUE" "   kubectl apply -f examples/aws/example-s3-bucket.yaml"
echo
print_message "$YELLOW" "3. Check resource status:"
print_message "$BLUE" "   kubectl get bucket"
print_message "$BLUE" "   kubectl describe bucket ${bucket_name}"
echo
print_message "$YELLOW" "4. View all AWS resources:"
print_message "$BLUE" "   kubectl get managed"
echo
print_message "$YELLOW" "5. Cleanup when done:"
print_message "$BLUE" "   kubectl delete -f examples/aws/"
echo
print_message "$RED" "WARNING: AWS resources may incur charges. Remember to delete them when finished!"
echo
print_message "$BLUE" "Example files location: examples/aws/"
print_message "$BLUE" "Provider check: kubectl get provider provider-aws -w"
echo
