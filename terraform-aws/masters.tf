data "local_file" "cluster_bootstrap_state" {
  filename = "${path.module}/cluster_bootstrap_state"
}

data "template_file" "master_userdata_script" {
  template = file("${path.module}/../templates/userdata/master.sh")
  vars = local.user_data_common
}

data "template_file" "bootstrap_userdata_script" {
  template = file("${path.module}/../templates/userdata/bootstrap.sh")
  vars = local.user_data_common
}

resource "aws_launch_template" "master" {
  name_prefix   = "elasticsearch-${var.es_cluster}-master-nodes"
  image_id      = data.aws_ami.elasticsearch.id
  instance_type = var.master_instance_type
  user_data     = base64encode(data.template_file.master_userdata_script.rendered)
  key_name      = var.key_name

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

resource "aws_autoscaling_group" "master_nodes" {
  count = length(keys(var.masters_count))

  name             = "elasticsearch-${var.es_cluster}-master-nodes-${keys(var.masters_count)[count.index]}"
  max_size         = var.masters_count[keys(var.masters_count)[count.index]]
  min_size         = var.masters_count[keys(var.masters_count)[count.index]]
  desired_capacity = var.masters_count[keys(var.masters_count)[count.index]]
  availability_zones = [keys(var.masters_count)[count.index]]
  default_cooldown = 30
  force_delete     = true

  vpc_zone_identifier     = local.cluster_subnet_ids[keys(var.masters_count)[count.index]]

  launch_template {
    id      = aws_launch_template.master.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = format("%s-master-node", var.es_cluster)
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
    value               = "master"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_ebs_volume.master]
}

resource "aws_instance" "bootstrap_node" {
  count                                = local.singlenode_mode || local.is_cluster_bootstrapped ? 0 : 1

  ami                                  = data.aws_ami.elasticsearch.id
  instance_type                        = var.master_instance_type
  instance_initiated_shutdown_behavior = "terminate"

  vpc_security_group_ids = concat(
    [aws_security_group.elasticsearch_security_group.id],
    var.additional_security_groups,
  )
  iam_instance_profile = aws_iam_instance_profile.elasticsearch.id
  user_data            = data.template_file.bootstrap_userdata_script.rendered
  key_name             = var.key_name
  subnet_id            = local.bootstrap_node_subnet_id

  tags = {
    Name        = "${var.es_cluster}-bootstrap-node"
    Environment = var.environment
    Cluster     = "${var.environment}-${var.es_cluster}"
    Role        = "bootstrap"
    AutoAttachDiskDisabled = "true"
  }
}

resource "null_resource" "cluster_bootstrap_state" {
  provisioner "local-exec" {
    command = "printf 1 > ${path.module}/cluster_bootstrap_state"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "printf 0 > ${path.module}/cluster_bootstrap_state"
  }

  depends_on = [aws_instance.bootstrap_node]
}