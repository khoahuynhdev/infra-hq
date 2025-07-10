variable "air-gapped-state" {
  type      = string
  sensitive = true
}

variable "intermediate_cloud_ca_ip_addresses" {
  type        = list(string)
  description = "IP addresses for the intermediate cloud CA"
  default     = ["10.0.0.0/16"]
}

variable "intermediate_cloud_ca_dns_names" {
  type        = list(string)
  description = "DNS names for the intermediate cloud CA"
  default     = ["some.dns.name"]
}
