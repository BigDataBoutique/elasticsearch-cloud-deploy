data "local_file" "cluster_bootstrap_state" {
  filename = "${path.module}/cluster_bootstrap_state"
}

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
    master                  = "true"
    data                    = "false"
    bootstrap_node          = "false"
    aws_region              = "${var.aws_region}"
    security_enabled        = "${var.security_enabled}"
    monitoring_enabled      = "${var.monitoring_enabled}"
    masters_count           = "${var.masters_count}"
    client_user             = ""
    client_pwd              = ""
    xpack_monitoring_host   = "${var.xpack_monitoring_host}"
  }
}

data "template_file" "bootstrap_userdata_script" {
  template = "${file("${path.module}/../templates/user_data.sh")}"

  vars {
    cloud_provider          = "aws"
    elasticsearch_data_dir  = "/var/lib/elasticsearch"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.master_heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    security_groups         = "${aws_security_group.elasticsearch_security_group.id}"
    asg_name                = "${aws_autoscaling_group.master_nodes.name}"
    availability_zones      = "${join(",", coalescelist(var.availability_zones, data.aws_availability_zones.available.names))}"
    master                  = "true"
    data                    = "false"
    bootstrap_node          = "true"
    aws_region              = "${var.aws_region}"
    security_enabled        = "${var.security_enabled}"
    monitoring_enabled      = "${var.monitoring_enabled}"
    masters_count           = "${var.masters_count}"
    client_user             = ""
    client_pwd              = ""
    xpack_monitoring_host   = "self"
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

  ebs_block_device {
    volume_type = "gp2"
    device_name = "/dev/xvdh"
    volume_size = "10" # GB
  }
  
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

  vpc_zone_identifier = ["${coalescelist(var.cluster_subnet_ids, data.aws_subnet_ids.selected.ids)}"]

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

resource "aws_instance" "bootstrap_node" {
  // Only create if cluster was not bootstrapped before, and not in single-node mode
  count = "${(var.masters_count == "0" && var.datas_count == "0") || data.local_file.cluster_bootstrap_state.content == "1" ? "0" : "1"}"

  ami   = "${data.aws_ami.elasticsearch.id}"
  instance_type = "${var.master_instance_type}"
  instance_initiated_shutdown_behavior = "terminate"
  vpc_security_group_ids = ["${concat(list(aws_security_group.elasticsearch_security_group.id), var.additional_security_groups)}"]
  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch.id}"
  user_data = "${data.template_file.bootstrap_userdata_script.rendered}"
  key_name = "${var.key_name}"
  subnet_id = "${element(coalescelist(var.cluster_subnet_ids, data.aws_subnet_ids.selected.ids), 0)}"

  tags {
    Name = "${var.es_cluster}-bootstrap-node"
    Environment = "${var.environment}"
    Cluster = "${var.environment}-${var.es_cluster}"
    Role = "bootstrap"
  }
}

resource "null_resource" "cluster_bootstrap_state" {
  provisioner "local-exec" {
    command = "printf 1 > ${path.module}/cluster_bootstrap_state"
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "printf 0 > ${path.module}/cluster_bootstrap_state"
  }

  depends_on = ["aws_instance.bootstrap_node"]
}