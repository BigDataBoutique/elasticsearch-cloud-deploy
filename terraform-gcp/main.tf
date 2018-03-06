provider "google" {
  credentials = "${file(${var.account_file})}"
  project = "${var.project_name}"
  region = "${var.region}"
}

resource "random_string" "vm-login-password" {
  length = 16
  special = true
  override_special = "!@#$%&-_"
}

data "google_compute_image" "elasticsearch" {
  family = "elasticsearch-6"
}
data "google_compute_image" "kibana" {
  family = "kibana-6"
}

resource "google_compute_network" "elasticsearch" {
  name                    = "foobar"
  auto_create_subnetworks = "true"
}
