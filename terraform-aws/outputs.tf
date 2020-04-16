output "clients_dns" {
  value = aws_lb.elasticsearch-alb.*.dns_name
}

output "vm_password" {
  value = random_string.vm-login-password.result
}