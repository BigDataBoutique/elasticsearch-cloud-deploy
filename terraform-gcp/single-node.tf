data "template_file" "singlenode_userdata_script" {
  template = "${file("${path.module}/../templates/user_data.sh")}"

  vars = {
    cloud_provider          = "gcp"
    elasticsearch_data_dir  = "/var/lib/elasticsearch"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.data_heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    master                  = "false"
    data                    = "false"
    bootstrap_node          = "false"
    security_enabled        = "${var.security_enabled}"
    monitoring_enabled      = "${var.monitoring_enabled}"
    masters_count           = "${var.masters_count}"
    xpack_monitoring_host   = "${var.xpack_monitoring_host}"
    gcp_project_id          = "${var.gcp_project_id}"
    gcp_zone                = "${var.gcp_zone}"
    client_user             = "${var.client_user}"
    client_pwd              = "${random_string.vm-login-password.result}"
    aws_region              = ""
    availability_zones      = ""
    security_groups         = ""
  }
}

resource "google_compute_instance_group_manager" "singlenode" {
  provider  = google-beta

  name      = "${var.es_cluster}-igm-singlenode"
  project   = "${var.gcp_project_id}"
  zone      = "${var.gcp_zone}"

  named_port {
    name = "nginx"
    port = 8080
  }

  version {
    instance_template = google_compute_instance_template.singlenode.self_link
    name              = "primary"
  }

  base_instance_name = "${var.es_cluster}-singlenode"
}

resource "google_compute_autoscaler" "singlenode" {
  count = local.is_single_node ? 1 : 0

  name   = "${var.es_cluster}-autoscaler-singlenode"
  target = google_compute_instance_group_manager.singlenode.self_link

  autoscaling_policy {
    max_replicas    = 1
    min_replicas    = 1
    cooldown_period = 60
  }
}

resource "google_compute_instance_template" "singlenode" {
  provider       = google-beta

  name           = "${var.es_cluster}-instance-template-singlenode"
  project        = "${var.gcp_project_id}"
  machine_type   = "${var.data_machine_type}"
  can_ip_forward = true

  tags = ["${var.es_cluster}", "es-singlenode-node", "http-server", "https-server"]

  metadata_startup_script = "${data.template_file.singlenode_userdata_script.rendered}"

  disk {
    source_image = data.google_compute_image.kibana.self_link
    boot         = true    
  }

  disk {
    device_name  = "xvdh"
    disk_type    = "pd-ssd"
    disk_size_gb = var.elasticsearch_volume_size
    source_image = ""
  }

  network_interface {
    network = var.cluster_network

    # Conditional access_config block
    dynamic "access_config" {
      for_each = var.public_facing ? [1] : []
      content {}
    }
  }

  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-ro"]
  }
}