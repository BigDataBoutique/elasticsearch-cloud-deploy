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
  description = "Allow access from LB"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.es_cluster}-client"
    cluster = "${var.es_cluster}"
  }

  ingress {
    from_port         = 8080
    to_port           = 8080
    protocol          = "tcp"
    security_groups   = ["${aws_security_group.elasticsearch_client_lb_security_group.id}"]
  }

  ingress {
    from_port         = 3000
    to_port           = 3000
    protocol          = "tcp"
    security_groups   = ["${aws_security_group.elasticsearch_client_lb_security_group.id}"]
  }

  ingress {
    from_port         = 9200
    to_port           = 9200
    protocol          = "tcp"
    security_groups   = ["${aws_security_group.elasticsearch_client_lb_security_group.id}"]
  }

  egress {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elasticsearch_client_lb_security_group" {
  name = "elasticsearch-${var.es_cluster}-client-lb-security-group"
  description = "Kibana and Grafana HTTP access from outside"
  vpc_id = "${var.vpc_id}"

  tags {
    cluster = "${var.es_cluster}"
  }

  ingress {
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

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

resource "aws_lb" "es_client_lb" {
  // Only create a LB if it's not a single-node configuration
  count = "${var.masters_count == "0" && var.datas_count == "0" ? "0" : "1"}"

  name            = "${format("%s-client-lb", var.es_cluster)}"
  security_groups = ["${aws_security_group.elasticsearch_client_lb_security_group.id}"]
  subnets         = ["${data.aws_subnet_ids.selected.ids}"]
  internal        = "${var.public_facing == "true" ? "false" : "true"}"

  load_balancer_type = "application"

  tags {
    Name = "${format("%s-client-lb", var.es_cluster)}"
  }
}

resource "aws_lb_listener" "kibana" {
  load_balancer_arn = "${aws_lb.es_client_lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.kibana.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "grafana" {
  load_balancer_arn = "${aws_lb.es_client_lb.arn}"
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.grafana.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "es" {
  load_balancer_arn = "${aws_lb.es_client_lb.arn}"
  port              = "9200"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.es.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "kibana" {
  name     = "${format("%s-client-lb-tg-kibana", var.es_cluster)}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    protocol = "HTTP"
    path = "/status"
  }
}

resource "aws_lb_target_group" "grafana" {
  name     = "${format("%s-client-lb-tg-grafana", var.es_cluster)}"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    protocol = "HTTP"
    path = "/login"
  }
}

resource "aws_lb_target_group" "es" {
  name     = "${format("%s-client-lb-tg-es", var.es_cluster)}"
  port     = 9200
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    protocol = "HTTP"
    path = "/"
  }
}

resource "aws_autoscaling_attachment" "kibana" {
  autoscaling_group_name = "${aws_autoscaling_group.client_nodes.id}"
  alb_target_group_arn   = "${aws_lb_target_group.kibana.arn}"
}

resource "aws_autoscaling_attachment" "grafana" {
  autoscaling_group_name = "${aws_autoscaling_group.client_nodes.id}"
  alb_target_group_arn   = "${aws_lb_target_group.grafana.arn}"
}

resource "aws_autoscaling_attachment" "es" {
  autoscaling_group_name = "${aws_autoscaling_group.client_nodes.id}"
  alb_target_group_arn   = "${aws_lb_target_group.es.arn}"
}
