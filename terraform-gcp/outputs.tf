output "clients_external_lb" {
  value = "${google_compute_global_forwarding_rule.clients-external.*.ip_address}"
}

output "vm_password" {
  value = "${random_string.vm-login-password.result}"
}