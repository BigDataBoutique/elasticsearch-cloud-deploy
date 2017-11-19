data "template_file" "client_userdata_script" {
  template = "${file("${path.root}/../templates/user_data.sh")}"

  vars {
    volume_name             = ""
    elasticsearch_data_dir  = ""
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "1g"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    security_groups         = ""
    aws_region              = "${var.azure_location}"
    availability_zones      = ""
    minimum_master_nodes    = "${format("%d", var.masters_count / 2 + 1)}"
    master                  = "false"
    data                    = "false"
    http_enabled            = "true"
    security_enabled        = "${var.security_enabled}"
    client_user             = "${var.client_user}"
    client_pwd              = "${var.client_pwd}"
  }
}

resource "azurerm_virtual_machine_scale_set" "client-nodes" {
  name = "es-${var.es_cluster}-client-nodes"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  location = "${var.azure_location}"
  "sku" {
    name = "Standard_DS4_v2" # TODO sizing & put in variables.tf
    tier = "Standard"
    capacity = "${var.datas_count}"
  }
  upgrade_policy_mode = "Manual"
  overprovision = false

  "os_profile" {
    computer_name_prefix = "es-${var.es_cluster}-c-"
    admin_username = "ubuntu"
    admin_password = "${random_string.vm-login-password.result}"
    custom_data = "${data.template_file.client_userdata_script.rendered}"
  }

  "network_profile" {
    name = "es-${var.es_cluster}-net-profile"
    primary = true

    "ip_configuration" {
      name = "es-${var.es_cluster}-ip-profile"
      subnet_id = "${azurerm_subnet.elasticsearch_subnet.id}"
      //      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.elasticsearch.id}"]
    }
  }

  storage_profile_image_reference {
    id = "${data.azurerm_image.kibana.id}"
  }

  "storage_profile_os_disk" {
    caching        = "ReadWrite"
    create_option  = "FromImage"
    managed_disk_type = "Standard_LRS" # TODO
  }

  // TODO use the below to replace password login with ssh keys
  // https://docs.microsoft.com/en-us/azure/virtual-machines/linux/create-ssh-keys-detailed
  //  os_profile_linux_config {
  //    disable_password_authentication = true
  //    ssh_keys {
  //      path     = "/home/azureuser/.ssh/authorized_keys"
  //      key_data = "${file("~/.ssh/id_rsa.pub")}"
  //    }
  //  }

  extension {
    name = "CustomScriptForLinux"
    publisher = "Microsoft.OSTCExtensions"
    type = "CustomScriptForLinux"
    type_handler_version = "1.5"
    settings = <<SETTINGS
    {
      "commandToExecute" : "echo 'hello'"
    }
    SETTINGS
  }
}

# TODO keyvault https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-automate-vm-deployment