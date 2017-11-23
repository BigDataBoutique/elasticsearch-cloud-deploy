output "es_image_id" {
  value = "${data.azurerm_image.elasticsearch.name}"
}

output "kibana_image_id" {
  value = "${data.azurerm_image.kibana.name}"
}

output "singlenode_public_dns" {
  value = "${azurerm_public_ip.single-node.fqdn}"
}

output "singlenode_public_ip" {
  value = "${azurerm_public_ip.single-node.public_ip_address_allocation}"
}

output "vm-password" {
  value = "${random_string.vm-login-password.result}"
}