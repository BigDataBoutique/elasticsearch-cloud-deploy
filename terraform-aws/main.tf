provider "aws" {
  region = var.aws_region
}

resource "random_string" "vm-login-password" {
  length  = 16
  special = false
}

locals {
  masters_count = length(flatten([for _, count in var.masters_count : range(count)])) # sum(...) going to be added to TF0.12 soon

  all_availability_zones = compact(tolist(setunion(
    keys(var.masters_count),
    keys(var.datas_count),
    keys(var.clients_count),
    toset([var.singlenode_az])
  )))

  cluster_subnet_ids = {
    for i, az in local.all_availability_zones : az => lookup(var.cluster_subnet_ids, az, element(data.aws_subnet_ids.subnets-per-az.*.ids, i))
  }

  clients_subnet_ids = {
    for i, az in local.all_availability_zones : az => lookup(var.clients_subnet_ids, az, element(data.aws_subnet_ids.subnets-per-az.*.ids, i))
  }

  flat_cluster_subnet_ids = flatten(values(local.cluster_subnet_ids))
  flat_clients_subnet_ids = flatten(values(local.clients_subnet_ids))

  bootstrap_node_subnet_id = var.bootstrap_node_subnet_id != "" ? var.bootstrap_node_subnet_id : coalescelist(local.flat_cluster_subnet_ids, [""])[0]

  singlenode_mode      = (length(keys(var.masters_count)) + length(keys(var.datas_count)) + length(keys(var.clients_count))) == 0
  singlenode_subnet_id = local.singlenode_mode ? local.cluster_subnet_ids[var.singlenode_az][0] : ""

  is_cluster_bootstrapped = data.local_file.cluster_bootstrap_state.content == "1"

  user_data_common = {
    cloud_provider           = "aws"
    elasticsearch_data_dir   = var.elasticsearch_data_dir
    elasticsearch_logs_dir   = var.elasticsearch_logs_dir
    es_cluster               = var.es_cluster
    es_environment           = "${var.environment}-${var.es_cluster}"
    security_groups          = aws_security_group.elasticsearch_security_group.id
    aws_region               = var.aws_region
    security_enabled         = var.security_enabled
    monitoring_enabled       = var.monitoring_enabled
    masters_count            = local.masters_count
    client_user              = var.client_user
    xpack_monitoring_host    = var.xpack_monitoring_host
    filebeat_monitoring_host = var.filebeat_monitoring_host
    s3_backup_bucket         = var.s3_backup_bucket
    use_g1gc                 = var.use_g1gc
    client_pwd               = random_string.vm-login-password.result
    master                   = false
    data                     = false
    bootstrap_node           = false

    ca_cert   = var.security_enabled ? join("", tls_self_signed_cert.ca[*].cert_pem) : ""
    node_cert = var.security_enabled ? join("", tls_locally_signed_cert.node[*].cert_pem) : ""
    node_key  = var.security_enabled ? join("", tls_private_key.node[*].private_key_pem) : ""

    DEV_MODE_scripts_s3_bucket = var.DEV_MODE_scripts_s3_bucket
  }
}

##############################################################################
# Elasticsearch
##############################################################################

resource "aws_security_group" "elasticsearch_security_group" {
  name        = "elasticsearch-${var.es_cluster}-security-group"
  description = "Elasticsearch ports with ssh"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.es_cluster}-elasticsearch"
    cluster = var.es_cluster
  }

  # ssh access from everywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inter-cluster communication over ports 9200-9400
  ingress {
    from_port = 9200
    to_port   = 9400
    protocol  = "tcp"
    self      = true
  }

  # allow inter-cluster ping
  ingress {
    from_port = 8
    to_port   = 0
    protocol  = "icmp"
    self      = true
  }

  # allow alb sg access
  ingress {
    from_port       = 9200
    to_port         = 9200
    protocol        = "tcp"
    security_groups = [aws_security_group.elasticsearch-alb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elasticsearch_clients_security_group" {
  name        = "elasticsearch-${var.es_cluster}-clients-security-group"
  description = "Kibana HTTP access from outside"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.es_cluster}-kibana"
    cluster = var.es_cluster
  }

  # allow alb sg access
  ingress {
    from_port       = 9200
    to_port         = 9200
    protocol        = "tcp"
    security_groups = [aws_security_group.elasticsearch-alb-sg.id]
  }
  ingress {
    from_port       = 5601
    to_port         = 5601
    protocol        = "tcp"
    security_groups = [aws_security_group.elasticsearch-alb-sg.id]
  }
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.elasticsearch-alb-sg.id]
  }
  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.elasticsearch-alb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
