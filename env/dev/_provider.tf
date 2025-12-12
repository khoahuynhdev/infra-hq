provider "tls" {}

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
