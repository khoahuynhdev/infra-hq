# VM Configuration
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "memory" {
  description = "Memory allocation in MiB"
  type        = number
}

variable "vcpu" {
  description = "Number of virtual CPUs"
  type        = number
}

variable "disk_size" {
  description = "Disk size in bytes"
  type        = number
}

# Storage Pool Configuration
variable "storage_pool_name" {
  description = "Name of the libvirt storage pool"
  type        = string
}

variable "storage_pool_path" {
  description = "Path to the libvirt storage pool"
  type        = string
}

# Base Image Configuration
variable "base_image_url" {
  description = "URL of the cloud image to use as base"
  type        = string
}

# Network Configuration
variable "network_name" {
  description = "Name of the libvirt network to attach to"
  type        = string
}

variable "domain" {
  description = "Domain name for the VM"
  type        = string
}

# SSH and User Configuration
variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "vm_user" {
  description = "Default user to create in the VM"
  type        = string
}

variable "vm_user_password_hashed" {
  description = "Hashed password for the VM user"
  type        = string
  sensitive   = true
}
