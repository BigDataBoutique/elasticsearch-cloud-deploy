data "template_file" "client_userdata_script" {
  template = "${file("${path.module}/../templates/gcp_user_data.sh")}"
  vars = merge(local.user_data_common, {
    heap_size      = "${var.client_heap_size}"
    startup_script = "client.sh"
  })
}


resource "google_compute_target_pool" "client" {
  name = "${var.es_cluster}-client-targetpool"
}



resource "google_compute_instance_group_manager" "client" {
  for_each = toset(keys(var.clients_count))

  provider = google-beta
  name     = "${var.es_cluster}-igm-client-${each.value}"
  project  = "${var.gcp_project_id}"
  zone     = each.value

  named_port {
    name = "nginx"
    port = 8080
  }

  named_port {
    name = "es"
    port = 9200
  }

  version {
    instance_template = google_compute_instance_template.client.self_link
    name              = "primary"
  }

  base_instance_name = "${var.es_cluster}-client"
  target_pools       = [google_compute_target_pool.client.self_link]
}

resource "google_compute_autoscaler" "client" {
  for_each = toset(keys(var.clients_count))

  name   = "${var.es_cluster}-autoscaler-client-${each.value}"
  zone   = each.value
  target = google_compute_instance_group_manager.client[each.value].self_link

  autoscaling_policy {
    max_replicas    = var.clients_count[each.value]
    min_replicas    = var.clients_count[each.value]
    cooldown_period = 60
  }
}

resource "google_compute_instance_template" "client" {
  provider       = google-beta
  name_prefix    = "${var.es_cluster}-instance-template-client"
  project        = "${var.gcp_project_id}"
  machine_type   = "${var.master_machine_type}"
  can_ip_forward = true

  tags = [
    "${var.es_cluster}",
    "es-client-node",
    "http-server",
    "https-server"
  ]

  metadata_startup_script = "${data.template_file.client_userdata_script.rendered}"

  labels = {
    environment = var.environment
    cluster     = "${var.environment}-${var.es_cluster}"
    role        = "client"
  }

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

  lifecycle {
    create_before_destroy = true
  }
}