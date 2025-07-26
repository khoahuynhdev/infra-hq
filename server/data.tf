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

// this is the reverse way of doing things 
// but I'll keep it for now
data "hcloud_firewall" "ssh_firewall" {
  name = "hetzner-infra-ssh"
}

data "hcloud_firewall" "web_firewall" {
  name = "hetzner-infra-web"
}

data "hcloud_firewall" "custom_firewall" {
  name = "hetzner-infra-custom"
}
