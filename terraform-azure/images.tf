# TODO pull via a prefix query
# https://github.com/terraform-providers/terraform-provider-azurerm/issues/577

data "azurerm_image" "elasticsearch" {
  name                = "elasticsearch5-2017-11-17T013212"
  resource_group_name = "packer-elasticsearch-images"
}

data "azurerm_image" "kibana" {
  name                = "kibana5-2017-11-23T074321"
  resource_group_name = "packer-elasticsearch-images"
}
