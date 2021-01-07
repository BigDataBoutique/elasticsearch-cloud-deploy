data "template_file" "data_userdata_script" {
  template = file("${path.module}/../templates/aws_user_data.sh")
  vars = merge(local.user_data_common, {
    startup_script = "data.sh",
    heap_size = var.data_heap_size
  })
}

resource "aws_launch_template" "data" {
  name_prefix   = "elasticsearch-${var.environment}-${var.es_cluster}-data-nodes"
  image_id      = data.aws_ami.elasticsearch.id
  instance_type = var.data_instance_type
  user_data     = base64encode(data.template_file.data_userdata_script.rendered)
  key_name      = var.key_name

  ebs_optimized = var.ebs_optimized

  iam_instance_profile {
    arn = aws_iam_instance_profile.elasticsearch.arn
  }

  network_interfaces {
    delete_on_termination       = true
    associate_public_ip_address = false
    security_groups = concat(
      [aws_security_group.elasticsearch_security_group.id],
      var.additional_security_groups,
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "data_nodes" {
  count = length(keys(var.datas_count))

  name               = "elasticsearch-${var.environment}-${var.es_cluster}-data-nodes-${keys(var.datas_count)[count.index]}"
  max_size           = var.datas_count[keys(var.datas_count)[count.index]]
  min_size           = var.datas_count[keys(var.datas_count)[count.index]]
  desired_capacity   = var.datas_count[keys(var.datas_count)[count.index]]
  default_cooldown   = 30
  force_delete       = true

  vpc_zone_identifier = local.cluster_subnet_ids[keys(var.datas_count)[count.index]]

  depends_on = [
    aws_autoscaling_group.master_nodes,
    aws_ebs_volume.data
  ]

  target_group_arns = [
    aws_lb_target_group.esearch-p9200-tg[0].arn,
  ]

  launch_template {
    id      = aws_launch_template.data.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = format("%s-data-node", var.es_cluster)
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
    value               = "data"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
