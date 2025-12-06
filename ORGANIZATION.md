# Project Organization

This document explains the project structure and organization.

## Directory Structure

```
crossplane-on-kind/
├── README.md                      # Main documentation
├── Makefile                       # Command shortcuts
├── setup.sh                       # Quick setup script
├── menu.sh                        # Interactive menu
├── .gitignore                     # Git exclusions
│
├── docs/                          # Documentation
│   ├── QUICKSTART.md              # 5-minute quick start
│   ├── GETTING_STARTED.md         # Step-by-step tutorial
│   ├── CHEATSHEET.md              # Command reference
│   └── TROUBLESHOOTING.md         # Problem solving guide
│
├── scripts/                       # Utility scripts
│   ├── status.sh                  # Check cluster status
│   ├── cleanup.sh                 # Cleanup resources
│   ├── validate.sh                # Validate setup
│   ├── diagnose.sh                # Diagnose issues
│   └── setup-aws-provider.sh      # AWS provider setup
│
├── config/                        # Configuration files
│   ├── kind-config.yaml           # Production cluster (3 nodes)
│   ├── kind-config-minimal.yaml   # Development cluster (1 node)
│   ├── provider-kubernetes.yaml   # Kubernetes provider config
│   └── provider-rbac.yaml         # RBAC configuration
│
└── examples/                      # Example resources
    ├── example-namespace.yaml     # Namespace example
    ├── example-deployment.yaml    # Deployment example
    ├── example-service.yaml       # Service example
    └── aws/                       # AWS provider examples
        ├── README.md              # AWS examples documentation
        ├── s3-bucket.yaml         # S3 bucket example
        ├── vpc-network.yaml       # VPC network example
        ├── ec2-instance.yaml      # EC2 instance example
        ├── rds-database.yaml      # RDS database example
        └── app-stack.yaml         # Complete application stack
```

## Design Principles

### 1. Clean Root Directory
Only user-facing files are kept in the root:
- `README.md` - Entry point documentation
- `Makefile` - Quick command shortcuts
- `setup.sh` - Primary setup script
- `menu.sh` - Interactive management interface

### 2. Organized Subdirectories

**docs/**
- Contains all supplementary documentation
- Separates detailed guides from main README
- Easy to navigate and maintain

**scripts/**
- Houses utility and helper scripts
- Scripts called by Makefile or main scripts
- Not intended for direct user execution

**config/**
- Centralized configuration management
- All YAML configuration files
- Easy to version and modify

**examples/**
- Sample resources and demonstrations
- Organized by provider (local/AWS)
- Ready-to-use examples

## Usage Patterns

### For End Users

```bash
# Quick start - use root-level scripts
./setup.sh                    # Setup everything
./menu.sh                     # Interactive menu

# Or use Makefile
make setup                    # Setup cluster
make status                   # Check status
make menu                     # Open menu
```

### For Developers

```bash
# Access utility scripts
./scripts/status.sh           # Direct status check
./scripts/diagnose.sh         # Run diagnostics
./scripts/validate.sh         # Validate setup

# Access documentation
cat docs/CHEATSHEET.md        # Command reference
cat docs/TROUBLESHOOTING.md   # Problem solving

# Modify configurations
vim config/kind-config.yaml   # Edit cluster config
vim config/provider-*.yaml    # Edit provider configs
```

## File Categories

### User-Facing (Root)
- **README.md** - Main documentation and entry point
- **Makefile** - Convenient command shortcuts
- **setup.sh** - Automated setup and installation
- **menu.sh** - Interactive management interface

### Documentation (docs/)
- **QUICKSTART.md** - Fast 5-minute setup guide
- **GETTING_STARTED.md** - Comprehensive tutorial
- **CHEATSHEET.md** - Quick command reference
- **TROUBLESHOOTING.md** - Common issues and solutions

### Utility Scripts (scripts/)
- **status.sh** - Display cluster and resource status
- **cleanup.sh** - Clean up resources and cluster
- **validate.sh** - Validate installation and setup
- **diagnose.sh** - Diagnose system and cluster issues
- **setup-aws-provider.sh** - Interactive AWS provider setup

### Configuration (config/)
- **kind-config.yaml** - Production cluster configuration (3 nodes)
- **kind-config-minimal.yaml** - Development cluster (1 node)
- **provider-kubernetes.yaml** - Kubernetes provider definition
- **provider-rbac.yaml** - RBAC permissions for provider

### Examples (examples/)
- **example-namespace.yaml** - Namespace creation via Crossplane
- **example-deployment.yaml** - Application deployment
- **example-service.yaml** - Service definition
- **aws/** - AWS provider examples with complete infrastructure

## Path References

### In Makefile
- Scripts: `./scripts/script-name.sh`
- Root scripts: `./setup.sh`, `./menu.sh`

### In setup.sh
- Config files: `config/kind-config.yaml`
- Examples: `examples/`

### In Scripts
- Other scripts: Relative paths from scripts/ directory
- Config files: `../config/` or absolute paths
- Examples: `../examples/` or absolute paths

## Benefits of This Organization

1. **Clean and Professional**
   - Root directory is uncluttered
   - Clear separation of concerns
   - Easy to understand at a glance

2. **User-Friendly**
   - Simple commands at root level
   - Documentation easily discoverable
   - Intuitive directory names

3. **Maintainable**
   - Related files grouped together
   - Easy to find and update files
   - Clear file responsibilities

4. **Scalable**
   - Easy to add new examples
   - Room for additional providers
   - Can add more documentation without clutter

5. **Git-Friendly**
   - .gitignore covers all directories
   - Easy to track changes by category
   - Clear commit organization

## Quick Reference

### Common Commands
```bash
# Setup and management
./setup.sh                    # Initial setup
./menu.sh                     # Interactive menu
make help                     # Show all commands

# Status and validation
make status                   # Check status
make validate                 # Validate setup

# Examples
make apply-examples           # Apply all examples
make clean-examples           # Remove examples

# Documentation
ls docs/                      # List all docs
cat docs/QUICKSTART.md        # Quick start guide
```

### File Locations
```bash
# Configuration
config/kind-config.yaml              # Cluster config
config/provider-kubernetes.yaml      # Provider config

# Scripts
scripts/status.sh                    # Status checker
scripts/diagnose.sh                  # Diagnostics

# Documentation
docs/CHEATSHEET.md                   # Commands
docs/TROUBLESHOOTING.md              # Problems

# Examples
examples/example-namespace.yaml      # K8s examples
examples/aws/                        # AWS examples
```

## Migration Notes

If you're updating from an older structure:

1. **Configuration files** moved from root to `config/`
2. **Documentation** moved from root to `docs/`
3. **Utility scripts** moved from root to `scripts/`
4. **User scripts** (setup.sh, menu.sh) remain at root
5. **Makefile** updated to reference new paths
6. **All functionality preserved** - just better organized

## Best Practices

1. **Keep root level clean** - Only user-facing files
2. **Document in docs/** - Not in root directory
3. **Scripts go in scripts/** - Unless user-facing
4. **Configs in config/** - All YAML configurations
5. **Examples organized** - By provider or type
6. **Update paths** - When moving files
7. **Test after changes** - Ensure everything works

## Support

- Main documentation: [README.md](README.md)
- Quick start: [docs/QUICKSTART.md](docs/QUICKSTART.md)
- Commands: [docs/CHEATSHEET.md](docs/CHEATSHEET.md)
- Problems: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
