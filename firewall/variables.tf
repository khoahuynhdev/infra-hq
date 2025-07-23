variable "firewall_name_prefix" {
  description = "Prefix for firewall names"
  type        = string
  default     = "firewall"
}

variable "tier" {
  description = "Deployment tier (e.g., dev, staging, prod)"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "ssh_allowed_ips" {
  description = "List of IP addresses/ranges allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpc_ip_range" {
  description = "VPC IP range for internal communication"
  type        = string
  default     = "10.0.0.0/16"
}

variable "custom_rules" {
  description = "List of custom firewall rules"
  type = list(object({
    direction       = string
    protocol        = string
    port            = optional(string)
    source_ips      = optional(list(string))
    destination_ips = optional(list(string))
  }))
  default = []
}