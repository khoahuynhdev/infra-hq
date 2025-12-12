provider "tls" {}

# Libvirt provider configuration
provider "libvirt" {
  uri = var.libvirt_uri
}

# Variable for libvirt URI (can be overridden in terraform.tfvars)
variable "libvirt_uri" {
  description = "Libvirt connection URI"
  type        = string
  default     = "qemu:///system"
}

terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9.1"
    }
  }
  backend "pg" {
    schema_name = "public"
    skip_schema_creation = true
  }
}
