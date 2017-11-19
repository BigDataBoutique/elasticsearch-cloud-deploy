output "es_image_id" {
  value = "${data.azurerm_image.elasticsearch.name}"
}

output "kibana_image_id" {
  value = "${data.azurerm_image.kibana.name}"
}

output "es_client_public_ip" {
  value = "${azurerm_public_ip.elasticsearch_ip.fqdn}"
}

output "vm-password" {
  value = "${random_string.vm-login-password.result}"
}