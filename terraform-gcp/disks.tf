locals {
  master_zone_flattened = toset(flatten([
    for zone, count in var.masters_count : [
      for i in range(0, count) : jsonencode({
        "zone" = zone,
        "index" = i,
        "name" = "${zone}-${i}"
      })
    ]
  ]))

  data_voters_zone_flattened = toset(flatten([
    for zone, count in var.data_voters_count : [
      for i in range(0, count) : jsonencode({
        "zone" = zone,
        "index" = i,
        "name" = "${zone}-${i}"
      })
    ]
  ]))

  data_zone_flattened = toset(flatten([
    for zone, count in var.datas_count : [
      for i in range(0, count) : jsonencode({
        "zone" = zone,
        "index" = i,
        "name" = "${zone}-${i}"
      })
    ]
  ]))
}

resource "google_compute_disk" "master" {
  for_each = local.master_zone_flattened

  name = "elasticsearch-${var.es_cluster}-master-${jsondecode(each.value)["name"]}"
  zone = jsondecode(each.value)["zone"]
  size = 10

  labels = {
    cluster-name = "${var.es_cluster}"
    volume-index = jsondecode(each.value)["index"]
    auto-attach-group = "master"
  }
}

resource "google_compute_disk" "data" {
  for_each = local.data_zone_flattened

  name = "elasticsearch-${var.es_cluster}-data-${jsondecode(each.value)["name"]}"
  zone = jsondecode(each.value)["zone"]
  size = var.elasticsearch_volume_size

  labels = {
    cluster-name = "${var.es_cluster}"
    volume-index = jsondecode(each.value)["index"]
    auto-attach-group = "data"
  }
}

resource "google_compute_disk" "data_voters" {
  for_each = local.data_voters_zone_flattened

  name = "elasticsearch-${var.es_cluster}-data-voters-${jsondecode(each.value)["name"]}"
  zone = jsondecode(each.value)["zone"]
  size = var.elasticsearch_volume_size

  labels = {
    cluster-name = "${var.es_cluster}"
    volume-index = jsondecode(each.value)["index"]
    auto-attach-group = "data-voters"
  }
}

resource "google_compute_disk" "singlenode" {
  count = local.singlenode_mode ? 1 : 0

  name = "elasticsearch-${var.es_cluster}-singlenode"
  zone = var.singlenode_zone
  size = var.elasticsearch_volume_size

  labels = {
    cluster-name = "${var.es_cluster}"
    volume-index = "0"
    auto-attach-group = "singlenode"
  }
}
