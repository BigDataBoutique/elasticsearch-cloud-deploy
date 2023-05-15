data "template_file" "data_userdata_script" {
  template = "${file("${path.module}/../templates/user_data.sh")}"

  vars = {
    cloud_provider          = "azure"
    volume_name             = ""
    elasticsearch_data_dir  = "${var.elasticsearch_data_dir}"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.data_heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    security_groups         = ""
    availability_zones      = ""
    master                  = "false"
    data                    = "true"
    bootstrap_node          = "false"
    node_roles              = "data,ingest"
    http_enabled            = "true"
    masters_count           = "${var.masters_count}"
    security_enabled        = "${var.security_enabled}"
    monitoring_enabled      = "${var.monitoring_enabled}"
    client_user             = ""
    client_pwd              = ""
    xpack_monitoring_host   = "${var.xpack_monitoring_host}"
    aws_region              = ""
    azure_resource_group    = ""
    azure_master_vmss_name  = ""

    ca_cert   = "${var.security_enabled ? join("", tls_self_signed_cert.ca[*].cert_pem) : ""}"
    node_cert = "${var.security_enabled ? join("", tls_locally_signed_cert.node[*].cert_pem) : ""}"
    node_key  = "${var.security_enabled ? join("", tls_private_key.node[*].private_key_pem) : ""}"
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "data-nodes" {
  count = "${var.datas_count == "0" ? "0" : "1"}"

  name = "es-${var.es_cluster}-data-nodes"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  location = "${var.azure_location}"

  sku = "${var.data_instance_type}"
  instances = "${var.datas_count}"

  overprovision = false

  computer_name_prefix = "${var.es_cluster}-data"
  admin_username = "ubuntu"
  admin_password = "${random_string.vm-login-password.result}"
  custom_data = base64encode(data.template_file.data_userdata_script.rendered)

  source_image_id = "${data.azurerm_image.elasticsearch.id}"
  network_interface {
    name = "es-${var.es_cluster}-net-profile"
    primary = true
    enable_accelerated_networking = true

    ip_configuration {
      name = "es-${var.es_cluster}-ip-profile"
      primary = true
      subnet_id = "${azurerm_subnet.elasticsearch_subnet.id}"
    }
  }

  # storage_profile_image_reference {
  #   id = "${data.azurerm_image.elasticsearch.id}"
  # }

  os_disk {
    caching        = "ReadWrite"
    # create_option  = "FromImage"
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

  data_disk {
    lun            = 0
    caching        = "ReadWrite"
    create_option  = "Empty"
    disk_size_gb   = "${var.elasticsearch_volume_size}"
    storage_account_type = "Standard_LRS"
  }
}