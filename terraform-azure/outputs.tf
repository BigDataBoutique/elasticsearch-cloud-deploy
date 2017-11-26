output "es_image_id" {
  value = "${data.azurerm_image.elasticsearch.name}"
}

output "kibana_image_id" {
  value = "${data.azurerm_image.kibana.name}"
}

output "public_dns" {
  value = "${azurerm_public_ip.clients.fqdn}"
}

output "public_ip_address" {
  value = "${azurerm_public_ip.clients.ip_address}"
}

output "vm_password" {
  value = "${random_string.vm-login-password.result}"
}