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
