output "intermediate_cloud_ca_private_key" {
  value     = tls_locally_signed_cert.intermediate_cloud_ca.ca_private_key_pem
  sensitive = true
}

output "intermediate_cloud_ca_cert" {
  value     = tls_locally_signed_cert.intermediate_cloud_ca.ca_cert_pem
  sensitive = true
}
