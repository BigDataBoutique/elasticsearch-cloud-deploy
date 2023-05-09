data "template_file" "client_userdata_script" {
  template = "${file("${path.module}/../templates/user_data.sh")}"

  vars = {
    cloud_provider          = "azure"
    volume_name             = ""
    elasticsearch_data_dir  = "/var/lib/elasticsearch"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "1g"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    security_groups         = ""
    availability_zones      = ""
    master                  = "false"
    data                    = "false"
    bootstrap_node          = "false"
    node_roles              = ""
    http_enabled            = "true"
    masters_count           = "${var.masters_count}"
    security_enabled        = "${var.security_enabled}"
    monitoring_enabled      = "${var.monitoring_enabled}"
    client_user             = "${var.client_user}"
    client_pwd              = "${random_string.vm-login-password.result}"
    xpack_monitoring_host   = "${var.xpack_monitoring_host}"
    aws_region              = ""
    azure_resource_group    = ""
    azure_master_vmss_name  = ""
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "client-nodes" {
  count = "${var.clients_count == "0" ? "0" : "1"}"

  name = "es-${var.es_cluster}-client-nodes"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  location = "${var.azure_location}"
  
  sku  = "${var.client_instance_type}"
  instances = "${var.clients_count}"
  
  #upgrade_policy_mode = "Manual"
  overprovision = false

  computer_name_prefix = "${var.es_cluster}-client"
  admin_username = "ubuntu"
  admin_password = "${random_string.vm-login-password.result}"
  custom_data = base64encode(data.template_file.client_userdata_script.rendered)

  network_interface {
    name = "es-${var.es_cluster}-net-profile"
    primary = true

    ip_configuration {
      name = "es-${var.es_cluster}-ip-profile"
      primary = true
      subnet_id = "${azurerm_subnet.elasticsearch_subnet.id}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.clients-lb-backend[count.index].id}"]
    }
  }

  source_image_id = "${data.azurerm_image.kibana.id}"

  os_disk {
    caching        = "ReadWrite"
    #create_option  = "FromImage"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username       = "ubuntu"
    public_key     = "${file(var.key_path)}"
  }
  # os_profile_linux_config {
  #   disable_password_authentication = true
  #   ssh_keys {
  #     path     = "/home/ubuntu/.ssh/authorized_keys"
  #     key_data = "${file(var.key_path)}"
  #   }
  # }
}