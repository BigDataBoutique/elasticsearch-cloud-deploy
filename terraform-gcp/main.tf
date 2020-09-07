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
  length  = 16
  special = false
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
    ports    = ["9200", "5601"]
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

resource "google_service_account" "gcs" {
  account_id   = "${var.es_cluster}-gcs"
  display_name = "${var.es_cluster}-gcs-service-account"
}

resource "google_service_account_key" "gcs" {
  service_account_id = google_service_account.gcs.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_storage_bucket" "snapshots" {
  count = var.gcs_snapshots_bucket != "" ? 1 : 0
  name  = var.gcs_snapshots_bucket
}

resource "google_storage_bucket_iam_member" "legacy-bucket-reader" {
  count = var.gcs_snapshots_bucket != "" ? 1 : 0
  bucket = join("", google_storage_bucket.snapshots[*].name)
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.gcs.email}"
}

resource "google_storage_bucket_iam_member" "object-admin" {
  count = var.gcs_snapshots_bucket != "" ? 1 : 0
  bucket = join("", google_storage_bucket.snapshots[*].name)
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gcs.email}"
}

locals {
  masters_count = length(flatten([for _, count in var.masters_count : range(count)])) # sum(...) going to be added to TF0.12 soon

  all_zones = compact(tolist(setunion(
    keys(var.masters_count),
    keys(var.datas_count),
    keys(var.clients_count),
    toset([var.singlenode_zone])
  )))

  singlenode_mode         = (length(keys(var.masters_count)) + length(keys(var.datas_count)) + length(keys(var.clients_count))) == 0
  is_cluster_bootstrapped = data.local_file.cluster_bootstrap_state.content == "1"

  user_data_common = {
    cloud_provider           = "gcp"
    gcs_snapshots_bucket     = var.gcs_snapshots_bucket
    elasticsearch_data_dir   = var.elasticsearch_data_dir
    elasticsearch_logs_dir   = var.elasticsearch_logs_dir
    es_cluster               = var.es_cluster
    gcp_project_id           = var.gcp_project_id
    gcp_zones                = join(",", tolist(local.all_zones))
    es_environment           = "${var.environment}-${var.es_cluster}"
    security_enabled         = var.security_enabled
    monitoring_enabled       = var.monitoring_enabled
    masters_count            = local.masters_count
    client_user              = var.client_user
    xpack_monitoring_host    = var.xpack_monitoring_host
    filebeat_monitoring_host = var.filebeat_monitoring_host
    use_g1gc                 = var.use_g1gc
    client_pwd               = random_string.vm-login-password.result
    master                   = false
    data                     = false
    bootstrap_node           = false

    gcs_service_account_key = join("", google_service_account_key.gcs[*].private_key)
    ca_cert                 = var.security_enabled ? join("", tls_self_signed_cert.ca[*].cert_pem) : ""
    node_cert               = var.security_enabled ? join("", tls_locally_signed_cert.node[*].cert_pem) : ""
    node_key                = var.security_enabled ? join("", tls_private_key.node[*].private_key_pem) : "",

    DEV_MODE_scripts_gcs_bucket = var.DEV_MODE_scripts_gcs_bucket
  }
}