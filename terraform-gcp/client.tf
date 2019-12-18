data "template_file" "client_userdata_script" {
  template = "${file("${path.module}/../templates/user_data.sh")}"

  vars = {
    cloud_provider          = "gcp"
    elasticsearch_data_dir  = "/var/lib/elasticsearch"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.client_heap_size}"
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

resource "google_compute_instance_group_manager" "client" {
  provider  = google-beta
  name      = "${var.es_cluster}-igm-client"
  project   = "${var.gcp_project_id}"
  zone      = "${var.gcp_zone}"

  named_port {
    name = "nginx"
    port = 8080
  }

  version {
    instance_template = google_compute_instance_template.client.self_link
    name              = "primary"
  }

  base_instance_name = "${var.es_cluster}-client"
}

resource "google_compute_autoscaler" "client" {
  count   = var.clients_count > 0 ? 1 : 0

  name    = "${var.es_cluster}-autoscaler-client"
  target  = google_compute_instance_group_manager.client.self_link

  autoscaling_policy {
    max_replicas    = var.clients_count
    min_replicas    = var.clients_count
    cooldown_period = 60
  }
}

resource "google_compute_instance_template" "client" {
  provider        = google-beta
  name            = "${var.es_cluster}-instance-template-client"
  project         = "${var.gcp_project_id}"
  machine_type    = "${var.master_machine_type}"
  can_ip_forward  = true

  tags = [
    "${var.es_cluster}",
    "es-client-node",
    "http-server",
    "https-server"
  ]

  metadata_startup_script = "${data.template_file.client_userdata_script.rendered}"

  disk {
    source_image = data.google_compute_image.kibana.self_link
    boot         = true    
  }

  network_interface {
    network = var.cluster_network
  }

  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-ro"]
  }
}