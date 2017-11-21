output "es_image_id" {
  value = "${data.azurerm_image.elasticsearch.name}"
}

output "kibana_image_id" {
  value = "${data.azurerm_image.kibana.name}"
}

output "jumpbox_public_ip" {
  value = "${azurerm_public_ip.jumpbox.fqdn}"
}

output "vm-password" {
  value = "${random_string.vm-login-password.result}"
}

output "subnet" {
  value = "${azurerm_subnet.elasticsearch_subnet.ip_configurations}"
}