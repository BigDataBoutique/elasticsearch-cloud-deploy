data "template_file" "data_userdata_script" {
  template = file("${path.module}/../templates/gcp_user_data.sh")
  vars = merge(local.user_data_common, {
    heap_size      = "${var.data_heap_size}"
    startup_script = "data.sh"
  })
}

resource "google_compute_instance_group_manager" "data" {
  for_each = toset(keys(var.datas_count))

  provider = google
  name     = "${var.es_cluster}-igm-data-${each.value}"
  project  = var.gcp_project_id
  zone     = each.value

  version {
    instance_template = google_compute_instance_template.data.self_link
    name              = "primary"
  }

  named_port {
    name = "es"
    port = 9200
  }

  base_instance_name = "${var.es_cluster}-data"
  target_pools       = var.enable_direct_data_access ? [google_compute_target_pool.client.self_link] : []

}

resource "google_compute_autoscaler" "data" {
  for_each = toset(keys(var.datas_count))

  name   = "${var.es_cluster}-autoscaler-data-${each.value}"
  zone   = each.value
  target = google_compute_instance_group_manager.data[each.value].self_link

  autoscaling_policy {
    max_replicas    = var.datas_count[each.value]
    min_replicas    = var.datas_count[each.value]
    cooldown_period = 60
  }
}

resource "google_compute_instance_template" "data" {
  provider       = google
  name_prefix    = "${var.es_cluster}-instance-template-data"
  project        = var.gcp_project_id
  machine_type   = var.data_machine_type
  can_ip_forward = false

  tags = ["${var.es_cluster}", "es-data-node"]

  metadata_startup_script = data.template_file.data_userdata_script.rendered

  labels = {
    environment = var.environment
    cluster     = "${var.environment}-${var.es_cluster}"
    role        = "data"
  }

  disk {
    source_image = data.google_compute_image.elasticsearch.self_link
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
