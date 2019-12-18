data "template_file" "data_userdata_script" {
  template = "${file("${path.module}/../templates/user_data.sh")}"

  vars = {
    cloud_provider          = "gcp"
    elasticsearch_data_dir  = "/var/lib/elasticsearch"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.data_heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    master                  = "false"
    data                    = "true"
    bootstrap_node          = "false"
    security_enabled        = "${var.security_enabled}"
    monitoring_enabled      = "${var.monitoring_enabled}"
    masters_count           = "${var.masters_count}"
    xpack_monitoring_host   = "${var.xpack_monitoring_host}"
    gcp_project_id          = "${var.gcp_project_id}"
    gcp_zone                = "${var.gcp_zone}"
    aws_region              = ""
    client_user             = ""
    client_pwd              = ""
    availability_zones      = ""
    security_groups         = ""
  }
}

resource "google_compute_instance_group_manager" "data" {
  provider  = google-beta
  name      = "${var.es_cluster}-igm-data"
  project   = "${var.gcp_project_id}"
  zone      = "${var.gcp_zone}"

  version {
    instance_template = google_compute_instance_template.data.self_link
    name              = "primary"
  }

  base_instance_name = "${var.es_cluster}-data"
}

resource "google_compute_autoscaler" "data" {
  count  = var.datas_count > 0 ? 1 : 0

  name   = "${var.es_cluster}-autoscaler-data"
  target = google_compute_instance_group_manager.data.self_link

  autoscaling_policy {
    max_replicas    = var.datas_count
    min_replicas    = var.datas_count
    cooldown_period = 60
  }
}

resource "google_compute_instance_template" "data" {
  provider       = google-beta
  name           = "${var.es_cluster}-instance-template-data"
  project        = "${var.gcp_project_id}"
  machine_type   = "${var.data_machine_type}"
  can_ip_forward = false

  tags = ["${var.es_cluster}", "es-data-node"]

  metadata_startup_script = "${data.template_file.data_userdata_script.rendered}"

  disk {
    source_image = data.google_compute_image.elasticsearch.self_link
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
    access_config {}
  }

  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-ro"]
  }
}