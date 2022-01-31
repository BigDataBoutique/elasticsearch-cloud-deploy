resource "google_storage_bucket" "dev" {
  count         = var.DEV_MODE_scripts_gcs_bucket != "" ? 1 : 0
  name          = var.DEV_MODE_scripts_gcs_bucket
  location      = var.gcp_region
  force_destroy = true
}