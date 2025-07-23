# Firewall for SSH access
resource "hcloud_firewall" "ssh_firewall" {
  name = "${var.firewall_name_prefix}-ssh"

  rule {
    direction  = "in"
    port       = "22"
    protocol   = "tcp"
    source_ips = var.ssh_allowed_ips
  }

  labels = {
    tier        = var.tier
    environment = var.environment
    service     = "ssh"
  }
}

# Firewall for HTTP/HTTPS traffic
resource "hcloud_firewall" "web_firewall" {
  name = "${var.firewall_name_prefix}-web"

  rule {
    direction  = "in"
    port       = "80"
    protocol   = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    port       = "443"
    protocol   = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  labels = {
    tier        = var.tier
    environment = var.environment
    service     = "web"
  }
}

# # Firewall for internal VPC communication
# resource "hcloud_firewall" "internal_firewall" {
#   name = "${var.firewall_name_prefix}-internal"
#
#   rule {
#     direction  = "in"
#     protocol   = "tcp"
#     source_ips = [var.vpc_ip_range]
#   }
#
#   rule {
#     direction  = "in"
#     protocol   = "udp"
#     source_ips = [var.vpc_ip_range]
#   }
#
#   rule {
#     direction  = "in"
#     protocol   = "icmp"
#     source_ips = [var.vpc_ip_range]
#   }
#
#   labels = {
#     tier        = var.tier
#     environment = var.environment
#     service     = "internal"
#   }
# }

# Custom firewall for additional rules
resource "hcloud_firewall" "custom_firewall" {
  count = length(var.custom_rules) > 0 ? 1 : 0
  name  = "${var.firewall_name_prefix}-custom"

  dynamic "rule" {
    for_each = var.custom_rules
    content {
      direction       = rule.value.direction
      port            = lookup(rule.value, "port", null)
      protocol        = rule.value.protocol
      source_ips      = lookup(rule.value, "source_ips", null)
      destination_ips = lookup(rule.value, "destination_ips", null)
    }
  }

  labels = {
    tier        = var.tier
    environment = var.environment
    service     = "custom"
  }
}

