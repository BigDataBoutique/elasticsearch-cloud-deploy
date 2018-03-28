output "clients_dns" {
  value = "${aws_lb.es_client_lb.*.dns_name}"
}

output "vm_password" {
  value = "${random_string.vm-login-password.result}"
}