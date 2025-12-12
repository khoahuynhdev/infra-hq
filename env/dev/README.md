# Dev Environment - Libvirt Domains

This directory contains the Terraform configuration for creating multiple libvirt VMs using the `for_each` pattern.

## Quick Start

1. **Set up your variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your actual values
   ```

2. **Generate SSH key (if needed):**
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   cat ~/.ssh/id_ed25519.pub  # Copy this to terraform.tfvars
   ```

3. **Generate hashed password:**
   ```bash
   openssl passwd -6
   # Enter your password when prompted
   # Copy the output to terraform.tfvars
   ```

4. **Initialize Terraform:**
   ```bash
   terraform init
   ```

5. **Review the plan:**
   ```bash
   terraform plan
   ```

6. **Apply the configuration:**
   ```bash
   terraform apply
   ```

## Configuration

### Adding More VMs

Edit `libvirt-domains.tf` and uncomment additional VMs in the `locals.vms` map, or add your own:

```hcl
locals {
  vms = {
    "my-vm-01" = {
      memory             = 2048  # MiB
      vcpu               = 2
      disk_size          = 21474836480  # 20GB in bytes
      storage_pool_name  = "default"
      storage_pool_path  = "/var/lib/libvirt/images"
      base_image_url     = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
      network_name       = "default"
      domain             = "local.lan"
      ssh_public_key     = var.ssh_public_key
      vm_user            = "fedora"
      vm_user_password_hashed = var.vm_user_password_hashed
    }
    # Add more VMs here...
  }
}
```

### Disk Size Calculator

Common disk sizes in bytes:
- 10GB = 10737418240
- 20GB = 21474836480
- 30GB = 32212254720
- 40GB = 42949672960
- 50GB = 53687091200
- 100GB = 107374182400

Or use this formula: `SIZE_IN_GB * 1024 * 1024 * 1024`

### Available Base Images

**Fedora:**
- Fedora 41: `https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2`
- Fedora 40: `https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-40-1.14.x86_64.qcow2`

**Ubuntu:**
- Ubuntu 22.04: `https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img`
- Ubuntu 24.04: `https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img`

**Debian:**
- Debian 12: `https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2`

## Managing VMs

### Access a VM

```bash
# SSH to a VM (after it's running)
# You'll need to find the IP address first
virsh domifaddr web-01

# Or use the default user
ssh fedora@<IP_ADDRESS>
# or for Ubuntu
ssh ubuntu@<IP_ADDRESS>
```

### Check VM Status

```bash
# List all VMs
virsh list --all

# Show VM info
virsh dominfo web-01

# Show VM IP address
virsh domifaddr web-01
```

### Console Access

```bash
# Connect to serial console
virsh console web-01

# Exit console with: Ctrl + ]
```

### Destroying VMs

```bash
# Destroy all VMs
terraform destroy

# Destroy specific VM
terraform destroy -target='module.libvirt_domain["web-01"]'
```

## Outputs

After applying, you can view the VM information:

```bash
# Show all outputs
terraform output

# Show specific output
terraform output vm_info
terraform output vm_ids
```

## Troubleshooting

### VM not starting
- Check libvirt logs: `journalctl -u libvirtd -f`
- Verify QEMU/KVM is working: `virsh capabilities`

### Cloud-init not working
- Check cloud-init logs inside VM: `sudo cloud-init status --long`
- View cloud-init output: `sudo cat /var/log/cloud-init-output.log`

### Network issues
- Verify network exists: `virsh net-list --all`
- Start default network: `virsh net-start default`
- Enable autostart: `virsh net-autostart default`

### Permission errors
- Ensure your user is in the libvirt group: `sudo usermod -a -G libvirt $USER`
- Re-login or use: `newgrp libvirt`

## Notes

- VMs are configured to autostart by default
- UEFI firmware is used (requires edk2-ovmf package)
- Cloud-init is used for initial configuration
- VNC is enabled for graphical access (localhost only)
