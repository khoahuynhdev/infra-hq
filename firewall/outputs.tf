output "ssh_firewall_id" {
  description = "ID of the SSH firewall"
  value       = hcloud_firewall.ssh_firewall.id
}

output "web_firewall_id" {
  description = "ID of the web firewall"
  value       = hcloud_firewall.web_firewall.id
}

# output "internal_firewall_id" {
#   description = "ID of the internal firewall"
#   value       = hcloud_firewall.internal_firewall.id
# }

output "custom_firewall_id" {
  description = "ID of the custom firewall (if created)"
  value       = length(hcloud_firewall.custom_firewall) > 0 ? hcloud_firewall.custom_firewall[0].id : null
}

output "firewall_ids" {
  description = "List of all firewall IDs"
  value = compact([
    hcloud_firewall.ssh_firewall.id,
    hcloud_firewall.web_firewall.id,
    # hcloud_firewall.internal_firewall.id,
    length(hcloud_firewall.custom_firewall) > 0 ? hcloud_firewall.custom_firewall[0].id : null
  ])
}

