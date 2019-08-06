provider "aws" {
  region = "${var.aws_region}"
}

resource "random_string" "vm-login-password" {
  length = 16
  special = true
  override_special = "!@#%&-_"
}

data "aws_availability_zones" "available" {}

##############################################################################
# Elasticsearch
##############################################################################

resource "aws_security_group" "elasticsearch_security_group" {
  name = "elasticsearch-${var.es_cluster}-security-group"
  description = "Elasticsearch ports with ssh"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.es_cluster}-elasticsearch"
    cluster = "${var.es_cluster}"
  }

  # ssh access from everywhere
  ingress {
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  # inter-cluster communication over ports 9200-9400
  ingress {
    from_port         = 9200
    to_port           = 9400
    protocol          = "tcp"
    self              = true
  }

  # allow inter-cluster ping
  ingress {
    from_port         = 8
    to_port           = 0
    protocol          = "icmp"
    self              = true
  }

  egress {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elasticsearch_clients_security_group" {
  name = "elasticsearch-${var.es_cluster}-clients-security-group"
  description = "Kibana HTTP access from outside"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.es_cluster}-kibana"
    cluster = "${var.es_cluster}"
  }

  # allow HTTP access to client nodes via ports 8080 and 80 (ELB)
  # better to disable, and either way always password protect!
  ingress {
    from_port         = 8080
    to_port           = 8080
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }
  ingress {
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  # allow HTTP access to client nodes via port 3000 for Grafana which has it's own login screen
  ingress {
    from_port         = 3000
    to_port           = 3000
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  egress {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "es_client_lb" {
  // Only create an ELB if it's not a single-node configuration
  count = "${var.masters_count == "0" && var.datas_count == "0" ? "0" : "1"}"

  name            = "${format("%s-client-lb", var.es_cluster)}"
  security_groups = ["${aws_security_group.elasticsearch_clients_security_group.id}"]
  subnets         = ["${coalescelist(var.clients_subnet_ids, list(data.aws_subnet_ids.selected.ids[0]))}"]
  internal        = "${var.public_facing == "true" ? "false" : "true"}"

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = "${var.lb_port}"
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 3000
    instance_protocol = "http"
    lb_port           = 3000
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 9200
    instance_protocol = "http"
    lb_port           = 9200
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/status"
    interval            = 6
  }

  tags {
    Name = "${format("%s-client-lb", var.es_cluster)}"
  }
}
