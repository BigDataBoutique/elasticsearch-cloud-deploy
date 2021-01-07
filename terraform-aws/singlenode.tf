data "template_file" "singlenode_userdata_script" {
  template = file("${path.module}/../templates/aws_user_data.sh")
  vars     = merge(local.user_data_common, {
    startup_script = "singlenode.sh",
    heap_size      = var.master_heap_size,
    eni_id         = aws_network_interface.single_node.id,
    eni_ipv4       = aws_network_interface.single_node.private_ip
  })
}

resource "aws_network_interface" "single_node" {
  security_groups = [
    aws_security_group.elasticsearch_security_group.id,
    aws_security_group.elasticsearch_clients_security_group.id
  ]
  subnet_id       = local.singlenode_subnet_id
  tags = {
    "Name": format("%s-elasticsearch", var.es_cluster),
    "Environment": var.environment,
    "Cluster":"${var.environment}-${var.es_cluster}",
    "Role":"singlenode"
  }
}

resource "aws_launch_template" "single_node" {
  name_prefix   = "elasticsearch-${var.environment}-${var.es_cluster}-single-node"
  image_id      = data.aws_ami.kibana_client.id
  instance_type = var.data_instance_type
  user_data     = base64encode(data.template_file.singlenode_userdata_script.rendered)
  key_name      = var.key_name

  ebs_optimized = var.ebs_optimized

  iam_instance_profile {
    arn = aws_iam_instance_profile.elasticsearch.arn
  }

  network_interfaces {
    delete_on_termination       = true
    associate_public_ip_address = false
    security_groups             = [aws_security_group.elasticsearch_security_group.id, aws_security_group.elasticsearch_clients_security_group.id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "singlenode" {
  count = local.singlenode_mode ? 1 : 0

  name             = "elasticsearch-${var.environment}-${var.es_cluster}-singlenode"
  min_size         = 1
  max_size         = 1
  desired_capacity = 1
  default_cooldown = 30
  force_delete     = true

  vpc_zone_identifier = [local.singlenode_subnet_id]

  launch_template {
    id      = aws_launch_template.single_node.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = format("%s-elasticsearch", var.es_cluster)
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
  tag {
    key                 = "Cluster"
    value               = "${var.environment}-${var.es_cluster}"
    propagate_at_launch = true
  }
  tag {
    key                 = "Role"
    value               = "singlenode"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_ebs_volume.singlenode, aws_network_interface.single_node]
}
