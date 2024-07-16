data "google_compute_image" "elasticsearch" {
  family = "elasticsearch-8"
}

data "google_compute_image" "kibana" {
  family = "kibana-8"
}
