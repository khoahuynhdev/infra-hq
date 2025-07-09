resource "hcloud_network" "shared-vpc" {
  name              = var.shared_vpc_name
  ip_range          = var.shared_vpc_ip_range
  delete_protection = true
}

resource "hcloud_network_subnet" "private-subnet-sg" {
  type         = "cloud"
  network_id   = hcloud_network.shared-vpc.id
  network_zone = var.zone["singapore"]
  ip_range     = "10.0.1.0/24"

  depends_on = [
    hcloud_network.shared-vpc
  ]
}
