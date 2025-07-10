locals {
  one_years = 8760
  ten_years = 87600
}

resource "tls_private_key" "intermediate_cloud_ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "intermediate_cloud_ca" {
  private_key_pem = tls_private_key.intermediate_cloud_ca.private_key_pem

  ip_addresses = var.intermediate_cloud_ca_ip_addresses // default ip of shared-vpc
  dns_names    = var.intermediate_cloud_ca_dns_names    // default dns of shared-vpc
  subject {
    common_name  = "K-Cloud Intermediate CA"
    organization = "K-Cloud PKI"
  }
}

resource "tls_locally_signed_cert" "intermediate_cloud_ca" {
  cert_request_pem   = tls_cert_request.intermediate_cloud_ca.cert_request_pem
  ca_private_key_pem = data.terraform_remote_state.pki.outputs.root_ca_private_key
  ca_cert_pem        = data.terraform_remote_state.pki.outputs.root_ca_cert

  validity_period_hours = local.one_years

  is_ca_certificate  = true
  set_subject_key_id = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "code_signing",
    "key_agreement",
    "ocsp_signing"
  ]
}

data "terraform_remote_state" "pki" {
  backend = "local"

  config = {
    path = pathexpand(var.air-gapped-state) // NOTE: unmount after use
  }
}
