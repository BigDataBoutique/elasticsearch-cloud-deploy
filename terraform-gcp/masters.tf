data "local_file" "cluster_bootstrap_state" {
  filename = "${path.module}/cluster_bootstrap_state"
}

data "template_file" "master_userdata_script" {
  template = "${file("${path.module}/../templates/gcp_user_data.sh")}"
  vars = merge(local.user_data_common, {
    heap_size      = "${var.master_heap_size}"
    startup_script = "master.sh"
  })
}

data "template_file" "bootstrap_userdata_script" {
  template = "${file("${path.module}/../templates/gcp_user_data.sh")}"
  vars = merge(local.user_data_common, {
    heap_size      = "${var.master_heap_size}"
    startup_script = "bootstrap.sh"
  })
}

resource "google_compute_instance_group_manager" "master" {  
  for_each = toset(keys(var.masters_count))

  provider  = google-beta
  name      = "${var.es_cluster}-igm-master-${each.value}"
  project   = "${var.gcp_project_id}"
  zone      = each.value

  version {
    instance_template = google_compute_instance_template.master.self_link
    name              = "primary"
  }

  base_instance_name = "${var.es_cluster}-master"
}

resource "google_compute_autoscaler" "master" {
  for_each = toset(keys(var.masters_count))

  name   = "${var.es_cluster}-autoscaler-master-${each.value}"
  zone = each.value
  target = google_compute_instance_group_manager.master[each.value].self_link

  autoscaling_policy {
    max_replicas    = var.masters_count[each.value]
    min_replicas    = var.masters_count[each.value]
    cooldown_period = 60
  }
}

resource "google_compute_instance" "bootstrap_node" {
  count = local.singlenode_mode || local.is_cluster_bootstrapped ? 0 : 1

  name         = "${var.es_cluster}-bootstrap-node"
  machine_type = "${var.master_machine_type}"
  zone         = "${var.gcp_zone}"

  tags = ["${var.es_cluster}", "es-bootstrap-node"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.elasticsearch.self_link
    }
  }

  network_interface {
    network = var.cluster_network
  }

  metadata_startup_script = "${data.template_file.bootstrap_userdata_script.rendered}"

  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-ro"]
  }
}

resource "google_compute_instance_template" "master" {
  provider       = google-beta
  name_prefix           = "${var.es_cluster}-instance-template-master"
  project        = "${var.gcp_project_id}"
  machine_type   = "${var.master_machine_type}"
  can_ip_forward = false

  tags = ["${var.es_cluster}", "es-master-node"]

  metadata_startup_script = "${data.template_file.master_userdata_script.rendered}"

  labels = {
    environment = var.environment
    cluster = "${var.environment}-${var.es_cluster}"
    role = "master"
  }  

  disk {
    source_image = data.google_compute_image.elasticsearch.self_link
    boot         = true    
  }

  network_interface {
    network = var.cluster_network
  }

  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-ro"]
  }

  lifecycle {
    create_before_destroy = true
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

  depends_on = ["google_compute_instance.bootstrap_node"]
}