data "template_file" "client_userdata_script" {
  template = "${file("${path.root}/../templates/user_data.sh")}"

  vars {
    volume_name             = ""
    elasticsearch_data_dir  = ""
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "1g"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.environment}-${var.es_cluster}"
    security_groups         = "${aws_security_group.elasticsearch_security_group.id}"
    aws_region              = "${var.aws_region}"
    availability_zones      = "${var.availability_zones}"
    minimum_master_nodes    = "${format("%d", var.masters_count / 2 + 1)}"
    master                  = "false"
    data                    = "false"
    http_enabled            = "true"
  }
}

resource "aws_launch_configuration" "client" {
  image_id = "${var.kibana_ami_id}"
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
  availability_zones = ["${split(",", var.availability_zones)}"]
  max_size = "${var.clients_count}"
  min_size = "${var.clients_count}"
  desired_capacity = "${var.clients_count}"
  default_cooldown = 30
  force_delete = true
  launch_configuration = "${aws_launch_configuration.client.id}"

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
    value = "client"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}