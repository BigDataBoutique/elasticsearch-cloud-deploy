output "es_image_id" {
  value = "${data.azurerm_image.elasticsearch.id}"
}

output "kibana_image_id" {
  value = "${data.azurerm_image.kibana.id}"
}