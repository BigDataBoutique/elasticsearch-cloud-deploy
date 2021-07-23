data "template_file" "dataclient_userdata_script" {
  template = "${file("${path.module}/../templates/gcp_user_data.sh")}"
  vars = merge(local.user_data_common, {
    heap_size      = "${var.data_heap_size}"
    startup_script = "dataclient.sh"
  })
}
resource "google_compute_target_pool" "dataclient" {
  name = "${var.es_cluster}-dataclient-targetpool"
}

resource "google_compute_instance_group_manager" "dataclient" {
  for_each = toset(keys(var.dataclient_count))

  provider = google-beta
  name     = "${var.es_cluster}-igm-dataclient-${each.value}"
  project  = "${var.gcp_project_id}"
  zone     = each.value

  version {
    instance_template = google_compute_instance_template.dataclient.self_link
    name              = "primary"
  }

  base_instance_name = "${var.es_cluster}-dataclient"
}

resource "google_compute_autoscaler" "dataclient" {
  for_each = toset(keys(var.dataclient_count))

  name   = "${var.es_cluster}-autoscaler-dataclient-${each.value}"
  zone   = each.value
  target = google_compute_instance_group_manager.dataclient[each.value].self_link

  autoscaling_policy {
    max_replicas    = var.dataclient_count[each.value]
    min_replicas    = var.dataclient_count[each.value]
    cooldown_period = 60
  }
}

resource "google_compute_instance_template" "dataclient" {
  provider       = google-beta
  name_prefix    = "${var.es_cluster}-instance-template-dataclient"
  project        = "${var.gcp_project_id}"
  machine_type   = "${var.data_machine_type}"
  can_ip_forward = true

  tags = [
    "${var.es_cluster}",
    "es-dataclient-node",
    "http-server",
    "https-server"
    ]

  metadata_startup_script = "${data.template_file.dataclient_userdata_script.rendered}"

  labels = {
    environment = var.environment
    cluster     = "${var.environment}-${var.es_cluster}"
    role        = "dataclient"
  }

  disk {
    boot         = true
  }

  network_interface {
    network = var.cluster_network
  }

  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-ro"]
  }

  lifecycle {
    create_before_destroy = true
  }
}