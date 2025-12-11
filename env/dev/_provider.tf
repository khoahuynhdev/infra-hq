provider "tls" {}

terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  backend "pg" {
    schema_name = "public"
    skip_schema_creation = true
  }
}
