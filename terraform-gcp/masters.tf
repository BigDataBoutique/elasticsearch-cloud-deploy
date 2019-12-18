data "local_file" "cluster_bootstrap_state" {
  filename = "${path.module}/cluster_bootstrap_state"
}

data "template_file" "master_userdata_script" {
  template = "${file("${path.module}/../templates/user_data.sh")}"

  vars = {
    cloud_provider          = "gcp"
    elasticsearch_data_dir  = "/var/lib/elasticsearch"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.master_heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    master                  = "true"
    data                    = "false"
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

data "template_file" "bootstrap_userdata_script" {
  template = "${file("${path.module}/../templates/user_data.sh")}"

  vars = {
    cloud_provider          = "gcp"
    elasticsearch_data_dir  = "/var/lib/elasticsearch"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.master_heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    master                  = "true"
    data                    = "false"
    bootstrap_node          = "true"
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

resource "google_compute_instance_group_manager" "master" {
  provider  = google-beta
  name      = "${var.es_cluster}-igm-master"
  project   = "${var.gcp_project_id}"
  zone      = "${var.gcp_zone}"

  version {
    instance_template = google_compute_instance_template.master.self_link
    name              = "primary"
  }

  base_instance_name = "${var.es_cluster}-master"
}

resource "google_compute_autoscaler" "master" {
  count = var.masters_count > 0 ? 1 : 0

  name   = "${var.es_cluster}-autoscaler-master"
  target = google_compute_instance_group_manager.master.self_link

  autoscaling_policy {
    max_replicas    = var.masters_count
    min_replicas    = var.masters_count
    cooldown_period = 60
  }
}

resource "google_compute_instance" "bootstrap_node" {
  count        = "${local.is_single_node || data.local_file.cluster_bootstrap_state.content == "1" ? "0" : "1"}"

  name         = "${var.es_cluster}-bootstrap-node"
  machine_type = "${var.master_machine_type}"
  zone         = "${var.gcp_zone}"

  tags = ["${var.es_cluster}", "es-bootstrap-node"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.elasticsearch.self_link
    }
  }

  network_interface {
    network = var.cluster_network
  }

  metadata_startup_script = "${data.template_file.bootstrap_userdata_script.rendered}"

  service_account {
    scopes = ["compute-rw"]
  }
}

resource "google_compute_instance_template" "master" {
  provider       = google-beta
  name           = "${var.es_cluster}-instance-template-master"
  project        = "${var.gcp_project_id}"
  machine_type   = "${var.master_machine_type}"
  can_ip_forward = false

  tags = ["${var.es_cluster}", "es-master-node"]

  metadata_startup_script = "${data.template_file.master_userdata_script.rendered}"

  disk {
    source_image = data.google_compute_image.elasticsearch.self_link
    boot         = true    
  }

  disk {
    device_name  = "xvdh"
    disk_type    = "pd-standard"
    disk_size_gb = 10
    source_image = ""
  }

  network_interface {
    network = var.cluster_network
  }

  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-ro"]
  }
}


resource "null_resource" "cluster_bootstrap_state" {
  provisioner "local-exec" {
    command = "printf 1 > ${path.module}/cluster_bootstrap_state"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "printf 0 > ${path.module}/cluster_bootstrap_state"
  }

  depends_on = ["google_compute_instance.bootstrap_node"]
}