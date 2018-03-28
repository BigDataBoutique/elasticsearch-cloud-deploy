data "template_file" "master_userdata_script" {
  template = "${file("${path.module}/../templates/user_data.sh")}"

  vars {
    cloud_provider          = "aws"
    elasticsearch_data_dir  = "/var/lib/elasticsearch"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.master_heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    security_groups         = "${aws_security_group.elasticsearch_security_group.id}"
    availability_zones      = "${join(",", coalescelist(var.availability_zones, data.aws_availability_zones.available.names))}"
    minimum_master_nodes    = "${format("%d", var.masters_count / 2 + 1)}"
    master                  = "true"
    data                    = "false"
    http_enabled            = "false"
    security_enabled        = "${var.security_enabled}"
    monitoring_enabled      = "${var.monitoring_enabled}"
    client_user             = ""
    client_pwd              = ""
  }
}

resource "aws_launch_configuration" "master" {
  name_prefix = "elasticsearch-${var.es_cluster}-master-nodes"
  image_id = "${data.aws_ami.elasticsearch.id}"
  instance_type = "${var.master_instance_type}"
  security_groups = ["${concat(list(aws_security_group.elasticsearch_security_group.id), var.additional_security_groups)}"]
  associate_public_ip_address = false
  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch.id}"
  user_data = "${data.template_file.master_userdata_script.rendered}"
  key_name = "${var.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "master_nodes" {
  name = "elasticsearch-${var.es_cluster}-master-nodes"
  max_size = "${var.masters_count}"
  min_size = "${var.masters_count}"
  desired_capacity = "${var.masters_count}"
  default_cooldown = 30
  force_delete = true
  launch_configuration = "${aws_launch_configuration.master.id}"

  vpc_zone_identifier = ["${data.aws_subnet_ids.selected.ids}"]

  tag {
    key                 = "Name"
    value               = "${format("%s-master-node", var.es_cluster)}"
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
    value = "master"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}