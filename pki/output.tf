output "intermediate_cloud_ca_private_key" {
  value     = tls_locally_signed_cert.intermediate_cloud_ca.ca_private_key_pem
  sensitive = true
}

output "intermediate_cloud_ca_cert" {
  value     = tls_locally_signed_cert.intermediate_cloud_ca.ca_cert_pem
  sensitive = true
}

########### sg_01_ssh_key

output "sg_01_accessor_private_key" {
  value       = tls_private_key.sg_01_access.private_key_openssh
  sensitive   = true
  description = "Private key for SSH access to the sg_01 server."
}

output "sg_01_accessor_public_key" {
  value       = tls_private_key.sg_01_access.public_key_openssh
  sensitive   = true
  description = "Public key for SSH access to the sg_01 server."
}
###########
