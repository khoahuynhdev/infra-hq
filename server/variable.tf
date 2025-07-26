variable "location" {
  description = "default location for resources"
  type        = string
  default     = "ap-southeast"
}

variable "image" {
  type        = string
  description = "default image for resources"
  default     = "ubuntu-20.04"
}

variable "server_type" {
  type        = string
  description = "default server type for resources"
  default     = "cpx11"
}

variable "server_name" {
  type        = string
  description = "name of the server to create"
  default     = "generic-server"
}

variable "shared_vpc_name" {
  type        = string
  description = "name of the shared VPC"
  default     = "shared-vpc"
}

variable "shared_vpc_ip_range" {
  type        = string
  description = "IP range for the shared VPC"
  default     = "10.0.0.0/16"
}

variable "datacenter" {
  type        = map(any)
  description = "Datacenter for the resources"
  default = {
    "sin" : "sin-dc1"
  }
}

variable "tier" {
  type        = string
  description = "deployment tier"
  default     = "ingress"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "production"
}

variable "ssh_allowed_ips" {
  description = "List of IP addresses/ranges allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "custom_firewall_rules" {
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
