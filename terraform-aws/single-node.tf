data "template_file" "single_node_userdata_script" {
  template = "${file("${path.root}/../templates/user_data.sh")}"

  vars {
    volume_name             = "${var.volume_name}"
    elasticsearch_data_dir  = "${var.elasticsearch_data_dir}"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.data_heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    security_groups         = "${aws_security_group.elasticsearch_security_group.id}"
    aws_region              = "${var.aws_region}"
    availability_zones      = "${var.availability_zones}"
    minimum_master_nodes    = "${format("%d", var.masters_count / 2 + 1)}"
    master                  = "true"
    data                    = "true"
    http_enabled            = "true"
  }
}

resource "aws_launch_configuration" "single_node" {
  name = "elasticsearch-${var.es_cluster}-single-node"
  image_id = "${data.aws_ami.kibana_client.id}"
  instance_type = "${var.data_instance_type}"
  security_groups = ["${aws_security_group.elasticsearch_security_group.id}","${aws_security_group.elasticsearch_clients_security_group.id}"]
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch.id}"
  user_data = "${data.template_file.single_node_userdata_script.rendered}"
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

resource "aws_autoscaling_group" "single_node" {
  name = "elasticsearch-${var.es_cluster}-single-node"
  min_size = "0"
  max_size = "${var.masters_count == "0" && var.datas_count == "0" ? "1" : "0"}"
  desired_capacity = "${var.masters_count == "0" && var.datas_count == "0" ? "1" : "0"}"
  default_cooldown = 30
  force_delete = true
  launch_configuration = "${aws_launch_configuration.single_node.id}"

  vpc_zone_identifier = ["${var.vpc_subnets}"]

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
  tag {
    key = "Role"
    value = "single-node"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}