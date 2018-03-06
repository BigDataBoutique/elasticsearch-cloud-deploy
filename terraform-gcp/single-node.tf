data "template_file" "single_node_userdata_script" {
  template = "${file("${path.module}/../templates/user_data.sh")}"

  vars {
    cloud_provider          = "gcp"
    volume_name             = "${var.volume_name}"
    elasticsearch_data_dir  = "${var.elasticsearch_data_dir}"
    elasticsearch_logs_dir  = "${var.elasticsearch_logs_dir}"
    heap_size               = "${var.data_heap_size}"
    es_cluster              = "${var.es_cluster}"
    es_environment          = "${var.es_cluster}"
    security_groups         = ""
    aws_region              = "${var.region}"
    availability_zones      = ""
    minimum_master_nodes    = "${format("%d", var.masters_count / 2 + 1)}"
    master                  = "true"
    data                    = "true"
    http_enabled            = "true"
    security_enabled        = "${var.security_enabled}"
    monitoring_enabled      = "${var.monitoring_enabled}"
    client_user             = "${var.client_user}"
    client_pwd              = "${random_string.vm-login-password.result}"
  }
}

resource "google_compute_instance_template" "data-nodes" {
  name_prefix = "elasticsearch-${var.es_cluster}-data"
  description = "This template is used to create app server instances."

  instance_description = "Elasticsearch ${var.es_cluster} data nodes"
  machine_type         = "n1-standard-1"

  // Create a new boot disk from an image
  disk {
    source_image = "${data.google_compute_image.kibana}"
    auto_delete  = true
    boot         = true
  }

  // Use an existing disk resource
  disk {
    source      = "test_disk"
    auto_delete = true
    boot        = false
  }

  //network_interface {
  //  network = "default"
  //}

  metadata_startup_script = "${data.template_file.single_node_userdata_script.rendered}"

  service_account {
    // https://cloud.google.com/sdk/gcloud/reference/alpha/compute/instances/set-scopes#--scopes
    scopes = ["default"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "data-nodes" {
  name               = "data-nodes-instance-group-manager"
  instance_template  = "${google_compute_instance_template.data-nodes.self_link}"
  base_instance_name = "data-nodes-instance-group-manager"
  //zone               = "us-central1-f"
  target_size        = "${var.datas_count}"
}

//resource "google_compute_instance_group" "" {
//  name = ""
//
//}