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

variable "zone" {
  type        = map(any)
  description = "Location for the VPC resources"
  default = {
    "singapore" = "ap-southeast",
    "helsinki"  = "eu-central",
  }

}

