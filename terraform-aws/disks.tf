locals {
  master_az_flattened = flatten([
    for az, count in var.masters_count : [
      for i in range(0, count) : tomap({"az" = az, "index" = i})
    ]
  ])

  data_az_flattened = flatten([
    for az, count in var.datas_count : [
      for i in range(0, count) : tomap({"az" = az, "index" = i})
    ]
  ])

  client_az_flattened = flatten([
    for az, count in var.clients_count : [
      for i in range(0, count) : tomap({"az" = az, "index" = i})
    ]
  ])
}

resource "aws_ebs_volume" "master" {
  count = length(local.master_az_flattened)

  availability_zone = local.master_az_flattened[count.index]["az"]
  size = var.elasticsearch_volume_size
  type = "gp2"
  encrypted = var.volume_encryption

  tags = {
    Name = "elasticsearch-${var.es_cluster}-master-${count.index}"
    ClusterName = "${var.es_cluster}"
    VolumeIndex = local.master_az_flattened[count.index]["index"]
    AutoAttachGroup = "master"
  }
}

resource "aws_ebs_volume" "data" {
  count = length(local.data_az_flattened)

  availability_zone = local.data_az_flattened[count.index]["az"]
  size = var.elasticsearch_volume_size
  type = "gp2"
  encrypted = var.volume_encryption

  tags = {
    Name = "elasticsearch-${var.es_cluster}-data-${count.index}"
    ClusterName = "${var.es_cluster}"
    VolumeIndex = local.data_az_flattened[count.index]["index"]
    AutoAttachGroup = "data"
  }
}

resource "aws_ebs_volume" "singlenode" {
  count = local.singlenode_mode ? 1 : 0

  availability_zone = var.singlenode_az
  size = var.elasticsearch_volume_size
  type = "gp2"
  encrypted = var.volume_encryption

  tags = {
    Name = "elasticsearch-${var.es_cluster}-singlenode"
    ClusterName = "${var.es_cluster}"
    VolumeIndex = "0"
    AutoAttachGroup = "singlenode"
  }
}