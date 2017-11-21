data "template_file" "singlenode_userdata_script" {
  template = "${file("${path.root}/../templates/user_data.sh")}"

  vars {
    cloud_provider          = "azure"
    volume_name             = ""
    elasticsearch_data_dir  = "${var.elasticsearch_data_dir}"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.data_heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    security_groups         = ""
    aws_region              = "${var.azure_location}"
    availability_zones      = ""
    minimum_master_nodes    = "${format("%d", var.masters_count / 2 + 1)}"
    master                  = "true"
    data                    = "true"
    http_enabled            = "true"
    security_enabled        = "${var.security_enabled}"
    client_user             = "${var.client_user}"
    client_pwd              = "${random_string.vm-login-password.result}"
  }
}

