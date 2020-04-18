data "template_file" "singlenode_userdata_script" {
  template = file("${path.module}/../templates/aws_user_data.sh")
  vars     = merge(local.user_data_common, {
    startup_script = "singlenode.sh"
  })
}

resource "aws_launch_template" "single_node" {
  name_prefix   = "elasticsearch-${var.es_cluster}-single-node"
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

  name             = "elasticsearch-${var.es_cluster}-singlenode"
  min_size         = 1
  max_size         = 1
  desired_capacity = 1
  default_cooldown = 30
  force_delete     = true

  vpc_zone_identifier = [local.singlenode_subnet_id]

  target_group_arns = [
    aws_lb_target_group.esearch-p9200-tg.arn,
    aws_lb_target_group.kibana-p5601-tg.arn,
    aws_lb_target_group.grafana-p3000-tg.arn,
    aws_lb_target_group.cerebro-p9000-tg.arn,
  ]

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

  depends_on = [aws_ebs_volume.singlenode]
}