output "external_lb" {
  value = var.public_facing ? join("", google_compute_address.external-lb[*].address) : ""
}

output "internal_lb" {
  value = local.singlenode_mode ? join("", google_compute_forwarding_rule.internal-singlenode[*].service_name) : join("", google_compute_forwarding_rule.internal-client[*].service_name)
}

output "vm_password" {
  value = "${random_string.vm-login-password.result}"
}