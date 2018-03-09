provider "azurerm" {
  subscription_id = "${var.azure_subscription_id}"
  client_id = "${var.azure_client_id}"
  client_secret = "${var.azure_client_secret}"
  tenant_id = "${var.azure_tenant_id}"
}

resource "random_string" "vm-login-password" {
  length = 16
  special = true
  override_special = "!@#%&-_"
}

resource "azurerm_resource_group" "elasticsearch" {
  location = "${var.azure_location}"
  name = "elasticsearch-cluster-${var.es_cluster}"
}

resource "azurerm_virtual_network" "elasticsearch_vnet" {
  name                = "es-${var.es_cluster}-vnet"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  address_space       = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "elasticsearch_subnet" {
  name                 = "es-${var.es_cluster}-subnet"
  resource_group_name  = "${azurerm_resource_group.elasticsearch.name}"
  virtual_network_name = "${azurerm_virtual_network.elasticsearch_vnet.name}"
  address_prefix       = "10.1.0.0/24"
}