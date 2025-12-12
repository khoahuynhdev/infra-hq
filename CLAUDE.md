# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform-based infrastructure repository for managing Hetzner Cloud resources with a focus on security and modular architecture. The infrastructure supports both cloud (Hetzner) and local (libvirt) providers for hybrid deployments.

## Architecture

The infrastructure is organized into conceptual layers:

- **Level 1: Base** - PKI and IAM resources (foundational security components)
- **Level 2: Core** - VPCs, subnets, firewalls, and security groups
- **Level 3: Services** - Servers, databases, and message queues
- **Level 4: Applications** - Web applications, APIs, and mobile backends

### Module Structure

Each Terraform module (vpc, pki, server, firewall) follows a consistent structure:

- `main.tf` - Primary resource definitions
- `variables.tf` - Input variable declarations
- `output.tf` or `outputs.tf` - Output values
- `data.tf` - Data sources (where applicable)
- `_provider.tf` - Provider configuration (symlinked to root in some modules)

### Security Architecture

**Air-Gapped PKI**: The PKI module manages certificates in an air-gapped manner:

- Root CA is stored separately from cloud infrastructure
- Access via `air-gapped-state` variable pointing to local state file
- Mount/unmount workflow for security (see NOTE comments in pki/main.tf:46)
- Intermediate CA certificates are signed by the air-gapped root CA

**Firewall Strategy**: Multiple firewall resources for different purposes:

- SSH firewall with restricted source IPs
- Web firewall for HTTP/HTTPS (ports 80, 443)
- Custom firewall for dynamic rules via variables

## Common Commands

### Terraform Operations

```bash
# Initialize root module (uses both hcloud and libvirt providers)
terraform init

# Initialize a specific module
cd <module_name>  # vpc, pki, server, or firewall
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Format code
terraform fmt -recursive
```

### Working with Air-Gapped PKI

The PKI state is stored separately for security. When working with server or pki modules:

```bash
# Set the air-gapped state path (required for server and pki modules)
export TF_VAR_air_gapped_state="path/to/air-gapped-state.tfstate"

# Or pass it directly
terraform plan -var="air-gapped-state=path/to/state"
```

**IMPORTANT**: Unmount or secure the air-gapped state file after use.

### Module Dependencies

Modules have dependencies that must be applied in order:

1. **vpc** - Must be applied first (creates shared-vpc network)
2. **pki** - Can be applied after vpc (requires air-gapped root CA state)
3. **firewall** - Can be applied after vpc
4. **server** - Must be applied last (depends on vpc, pki, and firewall)

The server module uses `data` sources to reference:

- VPC network via `data.hcloud_network.shared_vpc`
- PKI outputs via `data.terraform_remote_state.pki`
- Firewall resources via `data.hcloud_firewall.*`

### Scripts

```bash
# Bootstrap VM with cloud image (faster than traditional ISO install)
./scripts/install-fedora-server-cloudimage.sh

# Setup Kubernetes on Fedora
./scripts/install-kubernetes-fedora.sh

# SSH helper script
./scripts/sshf
```

## Provider Configuration

This repository uses two Terraform providers:

- **hcloud** (~> 1.45) - Hetzner Cloud resources
- **libvirt** (~> 0.9.0) - Local VM management (QEMU/KVM)

Required variables:

- `hcloud_token` - Hetzner Cloud API token (sensitive)
- `libvirt_uri` - Libvirt connection URI (default: qemu:///system)

## Backend Configuration

Uses local backend for state management:

```hcl
terraform {
  backend "local" {}
}
```

State files are stored locally. The PKI module state should be kept air-gapped for security.

## Commit Conventions

This repository uses semantic/conventional commit format. Use the semantic-commit skill for generating commit messages:

```
<type>(<scope>): <subject>
```

Common types: `feat`, `fix`, `docs`, `refactor`, `chore`, `test`
Common scopes: `pki`, `vpc`, `server`, `firewall`, `terraform`, `networking`, `security`

Examples:

- `feat(pki): add intermediate CA certificates`
- `fix(vpc): correct subnet CIDR range`
- `chore(terraform): upgrade hetzner provider to 1.45`

## Key Technical Details

### Networking

- VPC CIDR: 10.0.0.0/16
- Singapore subnet: 10.0.1.0/24
- Server static IP: 10.0.1.10
- Network zone: ap-southeast (Singapore)

### Server Configuration

- Primary IP allocation with auto_delete=false for persistence
- SSH key injection from PKI module outputs
- Cloud-init configuration in server/cloud_config.yaml
- Multiple firewall attachments per server

### Resource Protection

- VPC has `delete_protection = true` to prevent accidental deletion
- Primary IPs have `auto_delete = false` for persistence across server recreations

### Provider Symlinks

~~Some modules use symlinked `_provider.tf` files pointing to `/home/khoa/projects/infra-hq/_provider.tf`. These may need updating if the repository path changes.~~ This is deprecated; all provider configurations are in the environment dir now
