# Example: Create multiple libvirt domains using for_each
# Fill in the actual values in terraform.tfvars or locals below

# Define your VMs as a local variable
# You can also move this to variables.tf and terraform.tfvars
locals {
  vms = {
    # Example VM 1 - Web Server
    "web-01" = {
      memory             = local.memory["2GB"]  # MiB
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

    # Example VM 2 - Database Server
    # "db-01" = {
    #   memory             = 4096  # MiB
    #   vcpu               = 4
    #   disk_size          = 53687091200  # 50GB in bytes
    #   storage_pool_name  = "default"
    #   storage_pool_path  = "/var/lib/libvirt/images"
    #   base_image_url     = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
    #   network_name       = "default"
    #   domain             = "local.lan"
    #   ssh_public_key     = var.ssh_public_key
    #   vm_user            = "fedora"
    #   vm_user_password_hashed = var.vm_user_password_hashed
    # }

    # Example VM 3 - Application Server
    # "app-01" = {
    #   memory             = 2048  # MiB
    #   vcpu               = 2
    #   disk_size          = 32212254720  # 30GB in bytes
    #   storage_pool_name  = "default"
    #   storage_pool_path  = "/var/lib/libvirt/images"
    #   base_image_url     = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
    #   network_name       = "default"
    #   domain             = "local.lan"
    #   ssh_public_key     = var.ssh_public_key
    #   vm_user            = "ubuntu"
    #   vm_user_password_hashed = var.vm_user_password_hashed
    # }
  }
}

# Create multiple VMs using for_each
module "libvirt_domain" {
  source   = "../../module/libvirt-domain"
  for_each = local.vms

  # VM name is the key from the map
  vm_name = each.key

  # VM configuration from the map values
  memory   = each.value.memory
  vcpu     = each.value.vcpu
  disk_size = each.value.disk_size

  # Storage pool configuration
  storage_pool_name = each.value.storage_pool_name
  storage_pool_path = each.value.storage_pool_path

  # Base image
  base_image_url = each.value.base_image_url

  # Network configuration
  network_name = each.value.network_name
  domain       = each.value.domain

  # SSH and user configuration
  ssh_public_key          = each.value.ssh_public_key
  vm_user                 = each.value.vm_user
  vm_user_password_hashed = each.value.vm_user_password_hashed
}
