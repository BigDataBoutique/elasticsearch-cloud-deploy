locals {
  is_single_node = "${var.masters_count == "0" && var.datas_count == "0"}"
}

provider "google" {
  credentials = "${var.gcp_credentials_path}"
  project     = "${var.gcp_project_id}"
  region      = "${var.gcp_region}"
  zone        = "${var.gcp_zone}"
}

provider "google-beta" {
  credentials = "${var.gcp_credentials_path}"
  project     = "${var.gcp_project_id}"
  region      = "${var.gcp_region}"
  zone        = "${var.gcp_zone}"
}

resource "random_string" "vm-login-password" {
  length = 16
  special = true
  override_special = "!@%&-_"
}

resource "google_compute_firewall" "internode" {
  name    = "${var.es_cluster}-firewall-allow-internode"
  network = var.cluster_network

  allow {
    protocol = "tcp"
    ports    = ["9200-9400"]
  }

  source_tags = [var.es_cluster]
}

resource "google_compute_firewall" "external" {
  count = var.public_facing ? 1 : 0

  name    = "${var.es_cluster}-firewall-allow-external"
  network = var.cluster_network

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "3000"]
  }
}

resource "google_compute_router" "router" {
  name    = "${var.es_cluster}-router"
  network = var.cluster_network
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.es_cluster}-router-nat"
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
