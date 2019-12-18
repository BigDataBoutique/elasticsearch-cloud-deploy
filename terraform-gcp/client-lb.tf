### Public LB

resource "google_compute_global_forwarding_rule" "clients-external" {
  count       = var.clients_count > 0 && var.public_facing ? 1 : 0

  name        = "${var.es_cluster}-clients-external"
  target      = google_compute_target_http_proxy.clients-external.self_link
  port_range  = "8080"
}

resource "google_compute_target_http_proxy" "clients-external" {
  name        = "${var.es_cluster}-target-proxy-clients-external"
  url_map     = google_compute_url_map.clients-external.self_link
}

resource "google_compute_url_map" "clients-external" {
  name            = "${var.es_cluster}-urlmap-clients-external"
  default_service = google_compute_backend_service.clients-external.self_link
}

resource "google_compute_backend_service" "clients-external" {
  name        = "${var.es_cluster}-backend-service-clients-external"

  port_name   = "nginx"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group_manager.client.instance_group
  }

  health_checks = [google_compute_http_health_check.clients-external.self_link]
}

resource "google_compute_http_health_check" "clients-external" {
  name          = "${var.es_cluster}-http-healthcheck-clients-external"
  project       = "${var.gcp_project_id}"
  port          = "8080"
  request_path  = "/status"
}