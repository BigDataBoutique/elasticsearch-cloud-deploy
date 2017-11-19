resource "azurerm_public_ip" "jumpbox" {
  name                         = "jumpbox-public-ip"
  location                     = "${var.azure_location}"
  resource_group_name          = "${azurerm_resource_group.elasticsearch.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${azurerm_resource_group.elasticsearch.name}-ssh"
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "jumpbox-nic"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"

  ip_configuration {
    name                          = "IPConfiguration"
    subnet_id                     = "${azurerm_subnet.elasticsearch_subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.jumpbox.id}"
  }
}

resource "azurerm_virtual_machine" "jumpbox" {
  name                  = "jumpbox"
  location              = "${var.azure_location}"
  resource_group_name   = "${azurerm_resource_group.elasticsearch.name}"
  network_interface_ids = ["${azurerm_network_interface.jumpbox.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    id = "${data.azurerm_image.kibana.id}"
  }

  storage_os_disk {
    name              = "jumpbox-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  "os_profile" {
    computer_name = "es-${var.es_cluster}-jumpbox"
    admin_username = "ubuntu"
    admin_password = "${random_string.vm-login-password.result}" # TODO randomize and change
    //    custom_data = "" # TODO
  }

  os_profile_linux_config {
    disable_password_authentication = false

//    ssh_keys {
//      path     = "/home/azureuser/.ssh/authorized_keys"
//      key_data = "${file("~/.ssh/id_rsa.pub")}"
//    }
  }
}