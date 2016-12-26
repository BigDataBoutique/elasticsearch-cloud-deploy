provider "aws" {
  region = "${var.aws_region}"
}

##############################################################################
# Elasticsearch
##############################################################################

resource "aws_security_group" "elasticsearch-security-group" {
  name = "elasticsearch-${var.es_cluster}-security-group"
  description = "Elasticsearch ports with ssh"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.es_cluster}-elasticsearch"
    cluster = "${var.es_cluster}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "kibana-security-group" {
  name = "kibana-${var.es_cluster}-security-group"
  description = "Kibana HTTP access from outside"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.es_cluster}-kibana"
    cluster = "${var.es_cluster}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# SSH access from anywhere
resource "aws_security_group_rule" "ssh_access" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.elasticsearch-security-group.id}"
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.elasticsearch-security-group.id}"
}

# Allow 9200-9400 access between nodes in the cluster
resource "aws_security_group_rule" "internal_cluster_access" {
  type              = "ingress"
  from_port         = 9200
  to_port           = 9400
  protocol          = "tcp"

  security_group_id = "${aws_security_group.elasticsearch-security-group.id}"
  source_security_group_id = "${aws_security_group.elasticsearch-security-group.id}"
}

# HTTP access to standard HTTP port from anywhere
resource "aws_security_group_rule" "external_http_access" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kibana-security-group.id}"
}

# HTTPS access to standard HTTPS port from anywhere
resource "aws_security_group_rule" "external_https_access" {
  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.kibana-security-group.id}"
}