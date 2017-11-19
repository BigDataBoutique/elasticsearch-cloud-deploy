provider "azurerm" {
  subscription_id = "${var.azure_subscription_id}"
  client_id = "${var.azure_client_id}"
  client_secret = "${var.azure_client_secret}"
  tenant_id = "${var.azure_tenant_id}"
}

resource "random_string" "vm-login-password" {
  length = 12
  special = true
}

resource "azurerm_resource_group" "elasticsearch" {
  location = "${var.azure_location}"
  name = "elasticsearch-cluster-${var.es_cluster}"
}

# TODO read
# https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-overview

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

resource "azurerm_public_ip" "elasticsearch_ip" {
  name                         = "es-${var.es_cluster}-public-ip"
  location                     = "${var.azure_location}"
  resource_group_name          = "${azurerm_resource_group.elasticsearch.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${azurerm_resource_group.elasticsearch.name}"
}

//resource "azurerm_availability_set" "data-nodes" {
//  location = "${var.azure_location}"
//  name = "elasticsearch-${var.es_cluster}-data-nodes"
//  resource_group_name = "${var.resource_group_name}"
//
//}


// TODO discovery via discovery.zen.ping.unicast.hosts: ["10.0.0.10", "10.0.0.11", "10.0.0.12"]