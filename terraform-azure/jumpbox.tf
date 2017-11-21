resource "azurerm_public_ip" "jumpbox" {
  name                         = "es-${var.es_cluster}-jumpbox-public-ip"
  location                     = "${var.azure_location}"
  resource_group_name          = "${azurerm_resource_group.elasticsearch.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${azurerm_resource_group.elasticsearch.name}-ssh"
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "es-${var.es_cluster}-jumpbox-nic"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"

  ip_configuration {
    name                          = "es-${var.es_cluster}-jumpbox-ip"
    subnet_id                     = "${azurerm_subnet.elasticsearch_subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.jumpbox.id}"
  }
}

resource "azurerm_virtual_machine" "jumpbox" {
  // Only create if it's a single-node configuration
//  count = "${var.masters_count == "0" && var.datas_count == "0" ? "1" : "0"}"
//  count = 0

  name                  = "es-${var.es_cluster}-jumpbox"
  location              = "${var.azure_location}"
  resource_group_name   = "${azurerm_resource_group.elasticsearch.name}"
  network_interface_ids = ["${azurerm_network_interface.jumpbox.id}"]
  vm_size               = "Standard_D12_v2"

  storage_image_reference {
    id = "${data.azurerm_image.kibana.id}"
  }

  storage_os_disk {
    name              = "es-${var.es_cluster}-jumpbox-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

//  storage_data_disk {
//    lun               = 0
//    caching           = "ReadWrite"
//    create_option     = "Empty"
//    disk_size_gb      = "${var.elasticsearch_volume_size}"
//    name              = "es-${var.es_cluster}-datadisk"
////    managed_disk_type = "Standard_LRS"
//  }

  "os_profile" {
    computer_name = "es-${var.es_cluster}-jumpbox"
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