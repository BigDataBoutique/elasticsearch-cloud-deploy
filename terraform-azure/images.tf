data "azurerm_image" "elasticsearch" {
  resource_group_name = "packer-elasticsearch-images"
  name_regex          = "^elasticsearch7-\\d{4,4}-\\d{2,2}-\\d{2,2}T\\d{6,6}"
  sort_descending     = true
}

data "azurerm_image" "kibana" {
  resource_group_name = "packer-elasticsearch-images"
  name_regex          = "^kibana7-\\d{4,4}-\\d{2,2}-\\d{2,2}T\\d{6,6}"
  sort_descending     = true
}
