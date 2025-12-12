# Libvirt Domains - Usage Examples

This document provides examples of how to create multiple VMs using the `for_each` pattern.

## Example 1: Simple Web Cluster

Create 3 web servers with identical configuration:

```hcl
locals {
  vms = {
    "web-01" = {
      memory             = 2048
      vcpu               = 2
      disk_size          = 21474836480  # 20GB
      storage_pool_name  = "default"
      storage_pool_path  = "/var/lib/libvirt/images"
      base_image_url     = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
      network_name       = "default"
      domain             = "web.local"
      ssh_public_key     = var.ssh_public_key
      vm_user            = "fedora"
      vm_user_password_hashed = var.vm_user_password_hashed
    }
    "web-02" = {
      memory             = 2048
      vcpu               = 2
      disk_size          = 21474836480
      storage_pool_name  = "default"
      storage_pool_path  = "/var/lib/libvirt/images"
      base_image_url     = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
      network_name       = "default"
      domain             = "web.local"
      ssh_public_key     = var.ssh_public_key
      vm_user            = "fedora"
      vm_user_password_hashed = var.vm_user_password_hashed
    }
    "web-03" = {
      memory             = 2048
      vcpu               = 2
      disk_size          = 21474836480
      storage_pool_name  = "default"
      storage_pool_path  = "/var/lib/libvirt/images"
      base_image_url     = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
      network_name       = "default"
      domain             = "web.local"
      ssh_public_key     = var.ssh_public_key
      vm_user            = "fedora"
      vm_user_password_hashed = var.vm_user_password_hashed
    }
  }
}
```

## Example 2: Mixed Environment (Web + DB + Cache)

Create different types of servers with varying resources:

```hcl
locals {
  vms = {
    "web-01" = {
      memory             = 2048   # 2GB
      vcpu               = 2
      disk_size          = 21474836480  # 20GB
      storage_pool_name  = "default"
      storage_pool_path  = "/var/lib/libvirt/images"
      base_image_url     = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
      network_name       = "default"
      domain             = "app.local"
      ssh_public_key     = var.ssh_public_key
      vm_user            = "ubuntu"
      vm_user_password_hashed = var.vm_user_password_hashed
    }
    "db-01" = {
      memory             = 8192   # 8GB for database
      vcpu               = 4
      disk_size          = 107374182400  # 100GB
      storage_pool_name  = "default"
      storage_pool_path  = "/var/lib/libvirt/images"
      base_image_url     = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
      network_name       = "default"
      domain             = "db.local"
      ssh_public_key     = var.ssh_public_key
      vm_user            = "ubuntu"
      vm_user_password_hashed = var.vm_user_password_hashed
    }
    "cache-01" = {
      memory             = 4096   # 4GB for Redis/Memcached
      vcpu               = 2
      disk_size          = 32212254720  # 30GB
      storage_pool_name  = "default"
      storage_pool_path  = "/var/lib/libvirt/images"
      base_image_url     = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
      network_name       = "default"
      domain             = "cache.local"
      ssh_public_key     = var.ssh_public_key
      vm_user            = "ubuntu"
      vm_user_password_hashed = var.vm_user_password_hashed
    }
  }
}
```

## Example 3: Using DRY Principle with Defaults

Reduce repetition by using local variables for common values:

```hcl
locals {
  # Common defaults
  default_config = {
    storage_pool_name  = "default"
    storage_pool_path  = "/var/lib/libvirt/images"
    network_name       = "default"
    domain             = "k8s.local"
    ssh_public_key     = var.ssh_public_key
    vm_user            = "fedora"
    vm_user_password_hashed = var.vm_user_password_hashed
    base_image_url     = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
  }

  # VM-specific configurations (merged with defaults in module call)
  vm_configs = {
    "k8s-master-01" = {
      memory    = 4096
      vcpu      = 2
      disk_size = 42949672960  # 40GB
    }
    "k8s-worker-01" = {
      memory    = 8192
      vcpu      = 4
      disk_size = 53687091200  # 50GB
    }
    "k8s-worker-02" = {
      memory    = 8192
      vcpu      = 4
      disk_size = 53687091200  # 50GB
    }
  }

  # Merge defaults with specific configs
  vms = {
    for name, config in local.vm_configs :
    name => merge(local.default_config, config)
  }
}
```

## Example 4: Dynamic VM Creation Based on Count

Create N identical VMs using dynamic blocks:

```hcl
locals {
  # Configuration
  worker_count = 5
  worker_config = {
    memory             = 4096
    vcpu               = 2
    disk_size          = 42949672960
    storage_pool_name  = "default"
    storage_pool_path  = "/var/lib/libvirt/images"
    base_image_url     = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
    network_name       = "default"
    domain             = "worker.local"
    ssh_public_key     = var.ssh_public_key
    vm_user            = "fedora"
    vm_user_password_hashed = var.vm_user_password_hashed
  }

  # Generate VM map
  vms = {
    for i in range(1, local.worker_count + 1) :
    "worker-${format("%02d", i)}" => local.worker_config
  }
}
```

## Example 5: Multi-Distribution Setup

Mix different Linux distributions:

```hcl
locals {
  vms = {
    "fedora-web-01" = {
      memory             = 2048
      vcpu               = 2
      disk_size          = 21474836480
      storage_pool_name  = "default"
      storage_pool_path  = "/var/lib/libvirt/images"
      base_image_url     = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
      network_name       = "default"
      domain             = "local"
      ssh_public_key     = var.ssh_public_key
      vm_user            = "fedora"
      vm_user_password_hashed = var.vm_user_password_hashed
    }
    "ubuntu-web-01" = {
      memory             = 2048
      vcpu               = 2
      disk_size          = 21474836480
      storage_pool_name  = "default"
      storage_pool_path  = "/var/lib/libvirt/images"
      base_image_url     = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
      network_name       = "default"
      domain             = "local"
      ssh_public_key     = var.ssh_public_key
      vm_user            = "ubuntu"
      vm_user_password_hashed = var.vm_user_password_hashed
    }
    "debian-web-01" = {
      memory             = 2048
      vcpu               = 2
      disk_size          = 21474836480
      storage_pool_name  = "default"
      storage_pool_path  = "/var/lib/libvirt/images"
      base_image_url     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
      network_name       = "default"
      domain             = "local"
      ssh_public_key     = var.ssh_public_key
      vm_user            = "debian"
      vm_user_password_hashed = var.vm_user_password_hashed
    }
  }
}
```

## Example 6: Using External Variables

Define VMs in a separate variable file for better organization:

**In `terraform.tfvars`:**
```hcl
vms = {
  "app-01" = {
    memory    = 2048
    vcpu      = 2
    disk_size = 21474836480
  }
  "app-02" = {
    memory    = 2048
    vcpu      = 2
    disk_size = 21474836480
  }
}

ssh_public_key = "ssh-ed25519 AAAAC3Nza... your_key_here"
vm_user_password_hashed = "$6$..."
```

**In `variables.tf`:**
```hcl
variable "vms" {
  description = "Map of VMs to create"
  type = map(object({
    memory    = number
    vcpu      = number
    disk_size = number
  }))
}
```

**In `libvirt-domains.tf`:**
```hcl
locals {
  # Common configuration
  common = {
    storage_pool_name  = "default"
    storage_pool_path  = "/var/lib/libvirt/images"
    base_image_url     = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
    network_name       = "default"
    domain             = "local"
    ssh_public_key     = var.ssh_public_key
    vm_user            = "fedora"
    vm_user_password_hashed = var.vm_user_password_hashed
  }

  # Merge variable VMs with common config
  vms = {
    for name, config in var.vms :
    name => merge(local.common, config)
  }
}

module "libvirt_domain" {
  source   = "../../module/libvirt-domain"
  for_each = local.vms

  vm_name = each.key
  # ... rest of configuration
}
```

## Managing Individual VMs

### Target specific VM

```bash
# Plan changes for specific VM
terraform plan -target='module.libvirt_domain["web-01"]'

# Apply changes for specific VM
terraform apply -target='module.libvirt_domain["web-01"]'

# Destroy specific VM
terraform destroy -target='module.libvirt_domain["web-01"]'
```

### Remove VM from configuration

To remove a VM, simply delete it from the `vms` map and run:

```bash
terraform apply
```

Terraform will destroy the VM that's no longer in the configuration.

### Add new VM

Add a new entry to the `vms` map and run:

```bash
terraform apply
```

Only the new VM will be created; existing VMs won't be affected.

## Best Practices

1. **Use consistent naming:** Use a pattern like `<role>-<number>` (e.g., `web-01`, `db-01`)

2. **Group similar VMs:** Keep VMs with similar purposes together in the map

3. **Use locals for defaults:** Reduce repetition by defining common configurations

4. **Comment your VMs:** Add comments to explain the purpose of each VM

5. **Separate environments:** Use different `.tf` files or directories for dev/staging/prod

6. **Version your images:** Pin specific image versions instead of using "latest"

7. **Resource naming:** Use meaningful resource names that reflect their purpose

8. **Disk sizing:** Plan disk sizes based on actual usage requirements plus 20-30% buffer

## Troubleshooting

### for_each errors

If you get errors like "for_each value must be a map or set", ensure your `vms` variable is a map:

```hcl
# ✅ Correct
locals {
  vms = {
    "vm-01" = { ... }
  }
}

# ❌ Wrong
locals {
  vms = [
    { name = "vm-01", ... }
  ]
}
```

### Duplicate resource errors

Each VM must have a unique key in the map. Check for duplicates:

```hcl
# ❌ Wrong - duplicate keys
locals {
  vms = {
    "web-01" = { ... }
    "web-01" = { ... }  # Duplicate!
  }
}
```

### Changes to for_each require recreation

Changing the map keys will cause Terraform to destroy and recreate VMs. Plan carefully:

```bash
# Review changes carefully
terraform plan

# If VMs are being recreated unnecessarily, consider using terraform state mv
```
