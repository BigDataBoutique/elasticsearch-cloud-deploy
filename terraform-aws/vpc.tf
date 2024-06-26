data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnets" "all-subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_route_tables" "vpc_route_tables" {
  vpc_id = var.vpc_id
}

data "aws_subnets" "subnets-per-az" {
  count  = length(local.all_availability_zones)

  filter {
    name   = "availability-zone"
    values = [local.all_availability_zones[count.index]]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

}

resource "aws_security_group" "vpc-endpoint" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  count = var.ec2_vpc_endpoint_id == "" ? 1 : 0
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [aws_security_group.vpc-endpoint.id]
  subnet_ids = compact(setunion(
    local.flat_cluster_subnet_ids,
    local.flat_clients_subnet_ids,
    [local.singlenode_subnet_id],
    [local.bootstrap_node_subnet_id]
  ))
}

resource "aws_vpc_endpoint" "autoscaling" {
  vpc_id              = var.vpc_id
  count = var.autoscaling_vpc_endpoint_id == "" ? 1 : 0
  service_name        = "com.amazonaws.${var.aws_region}.autoscaling"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [aws_security_group.vpc-endpoint.id]
  subnet_ids = compact(setunion(
    local.flat_cluster_subnet_ids,
    local.flat_clients_subnet_ids,
    [local.singlenode_subnet_id],
    [local.bootstrap_node_subnet_id]
  ))
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  count = var.s3_vpc_endpoint_id == "" ? 1 : 0
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.vpc_route_tables.ids
}
