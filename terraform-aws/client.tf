data "template_file" "client_userdata_script" {
  template = "${file("${path.module}/../templates/user_data.sh")}"

  vars {
    cloud_provider          = "aws"
    volume_name             = ""
    elasticsearch_data_dir  = "/var/lib/elasticsearch"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "1g"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    security_groups         = "${aws_security_group.elasticsearch_security_group.id}"
    aws_region              = "${var.aws_region}"
    availability_zones      = "${join(",", coalescelist(var.availability_zones, data.aws_availability_zones.available.names))}"
    minimum_master_nodes    = "${format("%d", var.masters_count / 2 + 1)}"
    master                  = "false"
    data                    = "false"
    http_enabled            = "true"
    security_enabled        = "${var.security_enabled}"
    monitoring_enabled      = "${var.monitoring_enabled}"
    client_user             = "${var.client_user}"
    client_pwd              = "${var.client_pwd}"
  }
}

resource "aws_launch_configuration" "client" {
  // Only create if it's not a single-node configuration
  count = "${var.masters_count == "0" && var.datas_count == "0" ? "0" : "1"}"

  name_prefix = "elasticsearch-${var.es_cluster}-client-nodes"
  image_id = "${data.aws_ami.kibana_client.id}"
  instance_type = "${var.master_instance_type}"
  security_groups = ["${aws_security_group.elasticsearch_security_group.id}","${aws_security_group.elasticsearch_clients_security_group.id}"]
  associate_public_ip_address = false
  iam_instance_profile = "${aws_iam_instance_profile.elasticsearch.id}"
  user_data = "${data.template_file.client_userdata_script.rendered}"
  key_name = "${var.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "client_nodes" {
  // Only create if it's not a single-node configuration
  count = "${var.masters_count == "0" && var.datas_count == "0" ? "0" : "1"}"

  name = "elasticsearch-${var.es_cluster}-client-nodes"
  max_size = "${var.clients_count}"
  min_size = "${var.clients_count}"
  desired_capacity = "${var.clients_count}"
  default_cooldown = 30
  force_delete = true
  launch_configuration = "${aws_launch_configuration.client.id}"

  load_balancers = ["${aws_elb.es_client_lb.id}"]

  vpc_zone_identifier = ["${data.aws_subnet_ids.selected.ids}"]

  tag {
    key                 = "Name"
    value               = "${format("%s-client-node", var.es_cluster)}"
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
    value = "client"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}