locals {
  cert_common_name      = "elasticsearch-cloud-deploy autogenerated CA"
  validity_period_hours = 365 * 24
  early_renewal_hours = 30 * 24
}

resource "tls_private_key" "ca" {
  count = var.security_enabled ? 1 : 0

  algorithm = "RSA"
}

resource "tls_self_signed_cert" "ca" {
  count = var.security_enabled ? 1 : 0

  #key_algorithm   = "RSA"
  private_key_pem = join("", tls_private_key.ca[*].private_key_pem)

  subject {
    common_name = local.cert_common_name
  }

  validity_period_hours = local.validity_period_hours
  early_renewal_hours = local.early_renewal_hours
  is_ca_certificate     = true

  allowed_uses = [
    "server_auth",
    "cert_signing",
    "crl_signing",
    "client_auth"
  ]
}

resource "tls_private_key" "node" {
  count = var.security_enabled ? 1 : 0

  algorithm = "RSA"
}

resource "tls_cert_request" "node" {
  count = var.security_enabled ? 1 : 0

  #key_algorithm   = "RSA"
  private_key_pem = join("", tls_private_key.node[*].private_key_pem)

  subject {
    common_name = local.cert_common_name
  }
}

resource "tls_locally_signed_cert" "node" {
  count = var.security_enabled ? 1 : 0

  #ca_key_algorithm   = "RSA"
  cert_request_pem   = join("", tls_cert_request.node[*].cert_request_pem)
  ca_private_key_pem = join("", tls_private_key.ca[*].private_key_pem)
  ca_cert_pem        = join("", tls_self_signed_cert.ca[*].cert_pem)

  validity_period_hours = local.validity_period_hours
  early_renewal_hours = local.early_renewal_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth"
  ]
}
