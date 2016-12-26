resource "aws_iam_role" "elasticsearch" {
  name               = "${var.es_cluster}-elasticsearch-discovery-role"
  assume_role_policy = "${file("${path.root}/../templates/ec2-role-trust-policy.json")}"
}

resource "aws_iam_role_policy" "elasticsearch" {
  name     = "${var.es_cluster}-elasticsearch-discovery-policy"
  policy   = "${file("${path.root}/../templates/ec2-allow-describe-instances.json")}"
  role     = "${aws_iam_role.elasticsearch.id}"
}

resource "aws_iam_instance_profile" "elasticsearch" {
  name = "${var.es_cluster}-elasticsearch-discovery-profile"
  path = "/"
  roles = ["${aws_iam_role.elasticsearch.name}"]
}
