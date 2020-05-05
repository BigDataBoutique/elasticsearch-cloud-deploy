data "template_file" "client_userdata_script" {
  template = file("${path.module}/../templates/aws_user_data.sh")
  vars = merge(local.user_data_common, {
    startup_script = "client.sh"
  })
}

resource "aws_launch_template" "client" {
  name_prefix   = "elasticsearch-${var.es_cluster}-client-nodes"
  image_id      = data.aws_ami.kibana_client.id
  instance_type = var.master_instance_type
  user_data     = base64encode(data.template_file.client_userdata_script.rendered)
  key_name      = var.key_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.elasticsearch.arn
  }

  network_interfaces {
    delete_on_termination       = true
    associate_public_ip_address = false
    security_groups = concat(
      [aws_security_group.elasticsearch_security_group.id],
      [aws_security_group.elasticsearch_clients_security_group.id],
      var.additional_security_groups,
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "client_nodes" {
  count = length(keys(var.clients_count))

  name               = "elasticsearch-${var.es_cluster}-client-nodes-${keys(var.clients_count)[count.index]}"
  max_size           = var.clients_count[keys(var.clients_count)[count.index]]
  min_size           = var.clients_count[keys(var.clients_count)[count.index]]
  desired_capacity   = var.clients_count[keys(var.clients_count)[count.index]]
  availability_zones = [keys(var.clients_count)[count.index]]
  default_cooldown   = 30
  force_delete       = true

  vpc_zone_identifier = local.clients_subnet_ids[keys(var.clients_count)[count.index]]

  target_group_arns = [
    aws_lb_target_group.esearch-p9200-tg.arn,
    aws_lb_target_group.kibana-p5601-tg.arn,
    aws_lb_target_group.grafana-p3000-tg.arn,
    aws_lb_target_group.cerebro-p9000-tg.arn,
  ]

  launch_template {
    id      = aws_launch_template.client.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = format("%s-client-node", var.es_cluster)
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
    value               = "client"
    propagate_at_launch = true
  }

  tag {
    key                 = "AutoAttachDiskDisabled"
    value               = "true"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
