output "shared-vpc-id" {
  value       = hcloud_network.shared-vpc.id
  description = "ID of the shared VPC"

}

output "private-subnet-sg" {
  value       = hcloud_network_subnet.private-subnet-sg.id
  description = "private subnet in Singapore for shared VPC"
}
