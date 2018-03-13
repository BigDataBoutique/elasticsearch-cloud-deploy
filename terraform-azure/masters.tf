data "template_file" "master_userdata_script" {
  template = "${file("${path.module}/../templates/user_data.sh")}"

  vars {
    cloud_provider          = "azure"
    volume_name             = ""
    elasticsearch_data_dir  = "/var/lib/elasticsearch"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.master_heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    security_groups         = ""
    availability_zones      = ""
    minimum_master_nodes    = "${format("%d", var.masters_count / 2 + 1)}"
    master                  = "true"
    data                    = "false"
    http_enabled            = "false"
    security_enabled        = "${var.security_enabled}"
    monitoring_enabled      = "${var.monitoring_enabled}"
    client_user             = ""
    client_pwd              = ""
  }
}

resource "azurerm_virtual_machine_scale_set" "master-nodes" {
  count = "${var.masters_count == "0" ? "0" : "1"}"

  name = "es-${var.es_cluster}-master-nodes"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  location = "${var.azure_location}"
  "sku" {
    name = "${var.master_instance_type}"
    tier = "Standard"
    capacity = "${var.masters_count}"
  }
  upgrade_policy_mode = "Manual"
  overprovision = false

  "os_profile" {
    computer_name_prefix = "${var.es_cluster}-master"
    admin_username = "ubuntu"
    admin_password = "${random_string.vm-login-password.result}"
    custom_data = "${data.template_file.master_userdata_script.rendered}"
  }

  "network_profile" {
    name = "es-${var.es_cluster}-net-profile"
    primary = true

    "ip_configuration" {
      name = "es-${var.es_cluster}-ip-profile"
      subnet_id = "${azurerm_subnet.elasticsearch_subnet.id}"
    }
  }

  storage_profile_image_reference {
    id = "${data.azurerm_image.elasticsearch.id}"
  }

  "storage_profile_os_disk" {
    caching        = "ReadWrite"
    create_option  = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = "${file(var.key_path)}"
    }
  }
}