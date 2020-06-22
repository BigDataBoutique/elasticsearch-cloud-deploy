locals {
  master_az_flattened = toset(flatten([
    for az, count in var.masters_count : [
      for i in range(0, count) : jsonencode({ "az" = az, "index" = i, "name" = "${az}-${i}" })
    ]
  ]))

  data_az_flattened = toset(flatten([
    for az, count in var.datas_count : [
      for i in range(0, count) : jsonencode({ "az" = az, "index" = i, "name" = "${az}-${i}" })
    ]
  ]))
}

resource "aws_ebs_volume" "master" {
  for_each = local.master_az_flattened

  availability_zone = jsondecode(each.value)["az"]
  size              = 10
  type              = "gp2"
  encrypted         = var.volume_encryption

  tags = {
    Name            = "elasticsearch-${var.es_cluster}-master-${jsondecode(each.value)["name"]}"
    ClusterName     = "${var.es_cluster}"
    VolumeIndex     = jsondecode(each.value)["index"]
    AutoAttachGroup = "master"
  }
}

resource "aws_ebs_volume" "data" {
  for_each = local.data_az_flattened

  availability_zone = jsondecode(each.value)["az"]
  size              = var.elasticsearch_volume_size
  type              = "gp2"
  encrypted         = var.volume_encryption

  tags = {
    Name            = "elasticsearch-${var.es_cluster}-data-${jsondecode(each.value)["name"]}"
    ClusterName     = "${var.es_cluster}"
    VolumeIndex     = jsondecode(each.value)["index"]
    AutoAttachGroup = "data"
  }
}

resource "aws_ebs_volume" "singlenode" {
  count = local.singlenode_mode ? 1 : 0

  availability_zone = var.singlenode_az
  size              = var.elasticsearch_volume_size
  type              = "gp2"
  encrypted         = var.volume_encryption

  tags = {
    Name            = "elasticsearch-${var.es_cluster}-singlenode"
    ClusterName     = "${var.es_cluster}"
    VolumeIndex     = "0"
    AutoAttachGroup = "singlenode"
  }
}
