data "hcloud_network" "shared_vpc" {
  name = "shared-vpc"
}

# importing the pki

variable "air-gapped-state" {
  type      = string
  sensitive = true
}

data "terraform_remote_state" "pki" {
  backend = "local"

  config = {
    path = pathexpand(var.air-gapped-state) // NOTE: unmount after use
  }
}
