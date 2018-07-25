data "template_file" "singlenode_userdata_script" {
  template = "${file("${path.module}/../templates/user_data.sh")}"

  vars {
    cloud_provider          = "azure"
    volume_name             = ""
    elasticsearch_data_dir  = "${var.elasticsearch_data_dir}"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.data_heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    security_groups         = ""
    availability_zones      = ""
    minimum_master_nodes    = "${format("%d", var.masters_count / 2 + 1)}"
    master                  = "true"
    data                    = "true"
    http_enabled            = "true"
    security_enabled        = "${var.security_enabled}"
    monitoring_enabled      = "${var.monitoring_enabled}"
    client_user             = "${var.client_user}"
    client_pwd              = "${local.client_pwd}"
  }
}

resource "azurerm_public_ip" "single-node" {
  count                        = "${var.masters_count == "0" && var.datas_count == "0" ? "1" : "0"}"
  name                         = "es-${var.es_cluster}-single-node-public-ip"
  location                     = "${var.azure_location}"
  resource_group_name          = "${azurerm_resource_group.elasticsearch.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${azurerm_resource_group.elasticsearch.name}"
}

resource "azurerm_network_interface" "single-node" {
  // Only create if it's a single-node configuration
  count = "${var.masters_count == "0" && var.datas_count == "0" ? "1" : "0"}"

  name                = "es-${var.es_cluster}-singlenode-nic"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"

  ip_configuration {
    name                          = "es-${var.es_cluster}-singlenode-ip"
    subnet_id                     = "${azurerm_subnet.elasticsearch_subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.single-node.id}"
  }
}

resource "azurerm_virtual_machine" "single-node" {
  // Only create if it's a single-node configuration
  count = "${var.masters_count == "0" && var.datas_count == "0" ? "1" : "0"}"

  name                  = "es-${var.es_cluster}-singlenode"
  location              = "${var.azure_location}"
  resource_group_name   = "${azurerm_resource_group.elasticsearch.name}"
  network_interface_ids = ["${azurerm_network_interface.single-node.id}"]
  vm_size               = "${var.data_instance_type}"

  storage_image_reference {
    id = "${data.azurerm_image.kibana.id}"
  }

  storage_os_disk {
    name              = "es-${var.es_cluster}-singlenode-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  "os_profile" {
    computer_name = "es-${var.es_cluster}-singlenode"
    admin_username = "ubuntu"
    admin_password = "${random_string.vm-login-password.result}"
    custom_data = "${data.template_file.singlenode_userdata_script.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = "${file(var.key_path)}"
    }
  }
}