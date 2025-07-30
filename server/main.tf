resource "hcloud_primary_ip" "sg_01_public" {
  name          = "primary_ip_test"
  type          = "ipv4"
  datacenter    = var.datacenter["sin"]
  assignee_type = "server"
  auto_delete   = false
  labels = {
    "network" = data.hcloud_network.shared_vpc.name
    "server"  = var.server_name
  }
}

# ssh-key
resource "hcloud_ssh_key" "sg_01" {
  name       = "sg-01-access"
  public_key = data.terraform_remote_state.pki.outputs.sg_01_accessor_public_key
}

resource "hcloud_server" "sg_01" {
  name        = var.server_name
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.sg_01.id]

  public_net {
    ipv4         = hcloud_primary_ip.sg_01_public.id
    ipv6_enabled = false
  }

  labels = {
    "network" = data.hcloud_network.shared_vpc.name
    "server"  = var.server_name
  }

}

resource "hcloud_server_network" "sg_01" {
  server_id  = hcloud_server.sg_01.id
  network_id = data.hcloud_network.shared_vpc.id
  ip         = "10.0.1.10"
}

# Attach firewalls to server

resource "hcloud_firewall_attachment" "server_web_firewall" {
  firewall_id = data.hcloud_firewall.web_firewall.id
  server_ids  = [hcloud_server.sg_01.id]
}

resource "hcloud_firewall_attachment" "server_custom_firewall" {
  firewall_id = data.hcloud_firewall.custom_firewall.id
  server_ids  = [hcloud_server.sg_01.id]
}
