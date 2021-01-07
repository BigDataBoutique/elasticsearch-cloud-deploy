data "template_file" "data_s3_backup" {
  template = file("${path.module}/../assets/s3-backup.json")

  vars = {
    s3_backup_bucket = var.s3_backup_bucket
  }
}

resource "aws_iam_role" "elasticsearch" {
  name               = "${var.environment}-${var.es_cluster}-elasticsearch-discovery-role"
  assume_role_policy = file("${path.module}/../assets/ec2-role-trust-policy.json")
}

resource "aws_iam_role_policy" "elasticsearch" {
  name = "${var.environment}-${var.es_cluster}-elasticsearch-node-init-policy"
  policy = file(
    "${path.module}/../assets/node-init.json",
  )
  role = aws_iam_role.elasticsearch.id
}

resource "aws_iam_role_policy" "s3_backup" {
  count  = var.s3_backup_bucket != "" ? 1 : 0
  name   = "${var.environment}-${var.es_cluster}-elasticsearch-backup-policy"
  policy = data.template_file.data_s3_backup.rendered
  role   = aws_iam_role.elasticsearch.id
}

resource "aws_iam_instance_profile" "elasticsearch" {
  name = "${var.environment}-${var.es_cluster}-elasticsearch-discovery-profile"
  path = "/"
  role = aws_iam_role.elasticsearch.name
}

