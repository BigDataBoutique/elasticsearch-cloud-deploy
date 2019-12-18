data "google_compute_image" "elasticsearch" {
  family = "elasticsearch-7"
}

data "google_compute_image" "kibana" {
  family = "kibana-7"
}
