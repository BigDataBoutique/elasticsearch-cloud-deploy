data "template_file" "dev-s3" {
  template = file("${path.module}/../assets/s3-backup.json")

  vars = {
    s3_backup_bucket = var.DEV_MODE_scripts_s3_bucket
  }
}

resource "aws_s3_bucket" "dev" {
  count = var.DEV_MODE_scripts_s3_bucket == "" ? 0 : 1

  bucket = "${var.DEV_MODE_scripts_s3_bucket}"
  region = var.aws_region
  acl    = "private"
}

resource "aws_iam_role_policy" "dev-s3" {
  count  = var.DEV_MODE_scripts_s3_bucket != "" ? 1 : 0
  name   = "${var.es_cluster}-elasticsearch-s3-devmode-policy"
  role   = aws_iam_role.elasticsearch.id
  policy = data.template_file.dev-s3.rendered
}