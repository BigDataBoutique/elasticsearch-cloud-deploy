### Public LB

locals {
  external_ports = var.public_facing ? toset(["9200", "5601"]) : toset([])
}

resource "google_compute_address" "external-lb" {
  count = var.public_facing ? 1 : 0
  name  = "${var.es_cluster}-external-lb"
}

resource "google_compute_forwarding_rule" "singlenode" {
  for_each = local.singlenode_mode ? local.external_ports : []

  ip_address = join("", google_compute_address.external-lb[*].address)
  name       = "${var.es_cluster}-external-singlenode-${each.value}"
  target     = google_compute_target_pool.singlenode.self_link
  port_range = each.value
}

resource "google_compute_forwarding_rule" "client" {
  for_each = local.singlenode_mode ? [] : local.external_ports

  ip_address = join("", google_compute_address.external-lb[*].address)
  name       = "${var.es_cluster}-external-client-${each.value}"
  target     = google_compute_target_pool.client.self_link
  port_range = each.value
}

### Internal LB

resource "google_compute_region_backend_service" "internal-singlenode" {
  count = local.singlenode_mode ? 1 : 0

  name          = "${var.es_cluster}-internal-singlenode"
  region        = var.gcp_region
  health_checks = [google_compute_health_check.internal.self_link]
  protocol      = "TCP"

  backend {
    group = google_compute_instance_group_manager.singlenode.instance_group
  }
}
resource "google_compute_forwarding_rule" "internal-singlenode" {
  count = local.singlenode_mode ? 1 : 0

  name                  = "${var.es_cluster}-internal-singlenode"
  region                = var.gcp_region
  service_label         = "${var.es_cluster}-internal"
  load_balancing_scheme = "INTERNAL"
  backend_service       = join("", google_compute_region_backend_service.internal-singlenode[*].self_link)
  all_ports             = true
}

resource "google_compute_region_backend_service" "internal-client" {
  count = local.singlenode_mode ? 0 : 1

  name          = "${var.es_cluster}-internal-client"
  region        = var.gcp_region
  health_checks = [google_compute_health_check.internal.self_link]
  protocol      = "TCP"

  dynamic "backend" {
    for_each = toset(keys(var.clients_count))
    content {
      group = google_compute_instance_group_manager.client[backend.value].instance_group
    }
  }
}
resource "google_compute_forwarding_rule" "internal-client" {
  count = local.singlenode_mode ? 0 : 1

  name                  = "${var.es_cluster}-internal-client"
  region                = var.gcp_region
  service_label         = "${var.es_cluster}-internal"
  load_balancing_scheme = "INTERNAL"
  backend_service       = join("", google_compute_region_backend_service.internal-client[*].self_link)
  all_ports             = true
}

resource "google_compute_health_check" "internal" {
  name = "${var.es_cluster}-internal-healthcheck"

  timeout_sec        = 1
  check_interval_sec = 1

  tcp_health_check {
    port = "9200"
  }
}
