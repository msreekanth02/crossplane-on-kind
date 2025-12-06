# Quick Start Guide

## Welcome to Crossplane on Kind!

This is your complete setup for running Crossplane locally. Everything is automated and ready to use.

## Step 1: Run Setup (First Time Only)

```bash
./setup.sh
```

This will:
- Check all prerequisites (Docker, Kind, kubectl, Helm)
- Create a Kind cluster with 1 control plane + 2 worker nodes
- Install Crossplane
- Install Kubernetes provider
- Create example files

Expected time: 3-5 minutes

## Step 2: Use the Interactive Menu

```bash
./menu.sh
```

This gives you a user-friendly interface for:
- Starting/stopping the cluster
- Managing resources
- Viewing logs and status
- Applying examples
- Accessing documentation

## Step 3: Try Examples

```bash
# Apply all Kubernetes examples
kubectl apply -f examples/

# Watch them being created
kubectl get object -w
```

## Quick Commands

```bash
./setup.sh              # Initial setup
./menu.sh               # Interactive menu (recommended)
./status.sh             # Quick status check
./cleanup.sh            # Cleanup options

make setup              # Same as ./setup.sh
make menu               # Open menu
make status             # Check status
make start              # Start cluster
make stop               # Stop cluster
make apply-examples     # Apply examples
```

## Common Tasks

### Start the Cluster
```bash
make start
# or
./menu.sh → Cluster Management → Start Cluster
```

### Stop the Cluster
```bash
make stop
# or
./menu.sh → Cluster Management → Stop Cluster
```

### Check Status
```bash
./status.sh
# or
make status
```

### Apply Examples
```bash
make apply-examples
# or
./menu.sh → Examples → Apply All Examples
```

### View Logs
```bash
./menu.sh → Monitoring & Status → View Logs
```

### Complete Cleanup
```bash
./cleanup.sh
# or
make delete
```

## What to Read

1. **First time?** → Read GETTING_STARTED.md
2. **Need commands?** → Check CHEATSHEET.md
3. **Having issues?** → See TROUBLESHOOTING.md
4. **Want details?** → Read README.md (comprehensive)
5. **Overview?** → See PROJECT_SUMMARY.md

## AWS Provider (Optional)

To use AWS resources:

```bash
./setup-aws-provider.sh
```

This will:
- Install AWS provider
- Set up your AWS credentials
- Create example AWS resources

## Project Structure

```
crossplane-on-kind/
│
├── Scripts (Executable)
│   ├── setup.sh                  ← Run this first
│   ├── menu.sh                   ← Main interface
│   ├── status.sh                 ← Quick status
│   ├── cleanup.sh                ← Cleanup options
│   └── setup-aws-provider.sh     ← AWS setup
│
├── Documentation
│   ├── README.md                 ← Complete guide
│   ├── GETTING_STARTED.md        ← Quick start
│   ├── CHEATSHEET.md             ← Command reference
│   ├── TROUBLESHOOTING.md        ← Problem solving
│   └── PROJECT_SUMMARY.md        ← Overview
│
├── Configuration
│   ├── kind-config.yaml          ← Cluster config
│   ├── Makefile                  ← Command shortcuts
│   └── .gitignore                ← Git exclusions
│
└── Examples (Created by setup)
    ├── example-namespace.yaml
    ├── example-deployment.yaml
    ├── example-service.yaml
    └── aws/
        ├── provider-aws.yaml
        ├── provider-config-aws.yaml
        ├── example-s3-bucket.yaml
        ├── example-vpc.yaml
        └── example-subnet.yaml
```

## Your First Session

```bash
# 1. Setup (first time only)
./setup.sh

# 2. Check it worked
./status.sh

# 3. Try the examples
kubectl apply -f examples/

# 4. Watch them create
kubectl get object

# 5. See the created resources
kubectl get namespace crossplane-example
kubectl get deployments -n crossplane-example

# 6. When done, stop the cluster
./menu.sh
# Select: Cluster Management → Stop Cluster
```

## Next Time You Work

```bash
# 1. Start the cluster
make start

# 2. Check status
./status.sh

# 3. Do your work...

# 4. Stop when done
make stop
```

## Need Help?

```bash
# Quick status
./status.sh

# Interactive help
./menu.sh → Documentation

# View troubleshooting
less TROUBLESHOOTING.md

# Check logs
make logs
```

## All Set!

You now have everything you need:
- Automated cluster management
- Interactive menu system
- Comprehensive documentation
- Working examples
- Troubleshooting guides

Start with: `./setup.sh`

Then use: `./menu.sh` for everything else!
