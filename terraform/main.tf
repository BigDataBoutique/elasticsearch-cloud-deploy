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

# SSH access from anywhere
resource "aws_security_group_rule" "ssh_access" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.elasticsearch-security-group.id}"
}

# elastic ports from anywhere.. we are using private ips so shouldn't
# have people deleting our indexes just yet
resource "aws_security_group_rule" "es_ports" {
  type              = "ingress"
  from_port         = 9200
  to_port           = 9400
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
