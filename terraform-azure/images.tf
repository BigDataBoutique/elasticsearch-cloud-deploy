# TODO pull via a prefix query

data "azurerm_image" "elasticsearch" {
  name                = "elasticsearch5-2017-11-17T013212"
  resource_group_name = "packer-elasticsearch-images"
}

data "azurerm_image" "kibana" {
  name                = "kibana5-2017-11-19T060151"
  resource_group_name = "packer-elasticsearch-images"
}
