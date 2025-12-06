# AWS Provider Examples

This directory contains examples for using Crossplane with AWS.

## Prerequisites

1. AWS account with appropriate permissions
2. AWS credentials configured
3. AWS provider installed in the cluster

## Setup

Run the AWS provider setup script:

```bash
./setup-aws-provider.sh
```

This will:
- Install the AWS provider
- Create a ProviderConfig with your AWS credentials
- Verify the installation

## Examples

### 1. S3 Bucket (`s3-bucket.yaml`)
Creates a simple S3 bucket in AWS.

```bash
kubectl apply -f examples/aws/s3-bucket.yaml
kubectl get bucket
```

### 2. VPC with Subnets (`vpc-network.yaml`)
Creates a VPC with public and private subnets.

```bash
kubectl apply -f examples/aws/vpc-network.yaml
kubectl get vpc
kubectl get subnet
```

### 3. EC2 Instance (`ec2-instance.yaml`)
Creates an EC2 instance in your VPC.

Note: Update the VPC ID and Subnet ID in the file first.

```bash
kubectl apply -f examples/aws/ec2-instance.yaml
kubectl get instance
```

### 4. RDS Database (`rds-database.yaml`)
Creates a PostgreSQL RDS database instance.

```bash
kubectl apply -f examples/aws/rds-database.yaml
kubectl get dbinstance
```

### 5. Complete Application Stack (`app-stack.yaml`)
Creates a complete application infrastructure:
- VPC with subnets
- Security groups
- RDS database
- EC2 instance

```bash
kubectl apply -f examples/aws/app-stack.yaml
```

## Checking Resource Status

```bash
# Check all AWS managed resources
kubectl get managed

# Check specific resource types
kubectl get bucket
kubectl get vpc
kubectl get subnet
kubectl get instance
kubectl get dbinstance

# Get detailed information
kubectl describe bucket my-crossplane-bucket
```

## Cleanup

To delete AWS resources:

```bash
# Delete individual resources
kubectl delete -f examples/aws/s3-bucket.yaml

# Delete all AWS resources
kubectl delete -f examples/aws/
```

WARNING: Make sure resources are fully deleted from AWS before removing the provider to avoid orphaned resources.

## Cost Considerations

- S3 bucket: Free tier available, minimal cost
- VPC: No cost for VPC itself
- EC2 instance: Charges apply, use t2.micro/t3.micro for minimal cost
- RDS: Charges apply, consider using db.t3.micro and enabling deletion protection

Always review AWS pricing before creating resources.

## Troubleshooting

### Provider not ready
```bash
kubectl get provider
kubectl describe provider provider-aws
```

### Resources not syncing
```bash
kubectl get providerconfig
kubectl describe providerconfig aws-provider
```

### Check provider logs
```bash
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-aws
```

## Security Notes

- Never commit AWS credentials to version control
- Use IAM roles with minimal required permissions
- Enable MFA on AWS accounts
- Regularly rotate credentials
- Use separate AWS accounts for dev/staging/prod
