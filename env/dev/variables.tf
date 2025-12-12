# Common variables for all VMs

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""  # Add your SSH public key here or in terraform.tfvars
}

variable "vm_user_password_hashed" {
  description = "Hashed password for VM user (generate with: openssl passwd -6)"
  type        = string
  sensitive   = true
  default     = ""  # Add hashed password here or in terraform.tfvars
}
