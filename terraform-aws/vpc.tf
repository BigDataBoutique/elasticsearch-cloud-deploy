data "aws_vpc" "selected" {
  id = "${var.vpc_id}"
}

data "aws_subnet_ids" "selected" {
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group" "vpc-endpoint" {
  vpc_id = "${var.vpc_id}" 

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


resource "aws_vpc_endpoint" "ec2" {
  vpc_id = "${var.vpc_id}"
  service_name = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  security_group_ids = ["${aws_security_group.vpc-endpoint.id}"]
  subnet_ids = ["${coalescelist(var.cluster_subnet_ids, data.aws_subnet_ids.selected.ids)}"]
}
