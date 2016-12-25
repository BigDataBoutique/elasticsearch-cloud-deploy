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

resource "template_file" "user_data" {
  template = "${file("${path.root}/../templates/user_data.sh")}"

  vars {
    volume_name             = "${var.volume_name}"
    elasticsearch_data_dir  = "${var.elasticsearch_data_dir}"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    security_groups         = "${aws_security_group.elasticsearch-security-group.id}"
    aws_region              = "${var.aws_region}"
    availability_zones      = "${var.availability_zones}"
    minimum_master_nodes    = "${format("%d", var.masters_count / 2 + 1)}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "elasticsearch" {
  image_id = "${var.elasticsearch_ami_id}"
  instance_type = "${var.elasticsearch_instance_type}"
  security_groups = ["${aws_security_group.elasticsearch-security-group.id}"]
  associate_public_ip_address = false
  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch.id}"
  user_data = "${template_file.user_data.rendered}"
  key_name = "${var.key_name}"

  lifecycle {
    create_before_destroy = true
  }

  ebs_block_device {
    device_name = "${var.volume_name}"
    volume_size = "${var.elasticsearch_volume_size}"
    encrypted = "${var.volume_encryption}"
  }
}

resource "aws_autoscaling_group" "elasticsearch-data-nodes" {
  availability_zones = ["${split(",", var.availability_zones)}"]
  max_size = "${var.datas_count}"
  min_size = "${var.datas_count}"
  desired_capacity = "${var.datas_count}"
  default_cooldown = 30
  force_delete = true
  launch_configuration = "${aws_launch_configuration.elasticsearch.id}"

  tag {
    key = "Name"
    value = "${format("%s-elasticsearch", var.es_cluster)}"
    propagate_at_launch = true
  }
  tag {
    key = "Environment"
    value = "${var.environment}"
    propagate_at_launch = true
  }
  tag {
    key = "Cluster"
    value = "${var.environment}-${var.es_cluster}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}