### MANDATORY ###
variable "es_cluster" {
  description = "Name of the elasticsearch cluster, used in node discovery"
}

variable "gcp_project_id" {
  type = "string"
}

variable "gcp_credentials_path" {
  type = "string"
}

variable "gcp_zone" {
  type = "string"
  default = "us-central1-a"
}

variable "gcp_region" {
  type = "string"
  default = "us-central1"
}

variable "environment" {
  default = "default"
}

variable "masters_count" {
  default = "0"
}

variable "datas_count" {
  default = "0"
}

variable "clients_count" {
  default = "0"
}

variable "cluster_network" {
  default = "default"
}

# client nodes have nginx installed on them, these credentials are used for basic auth
variable "client_user" {
  default = "exampleuser"
}

variable "public_facing" {
  description = "Whether or not the created cluster should be accessible from the public internet"
  default = true
}

variable "master_machine_type" {
  default = "n1-standard-1"
}

variable "data_machine_type" {
  default = "n1-standard-4"
}

variable "elasticsearch_volume_size" {
  type = "string"
  default = "100" # gb
}

variable "elasticsearch_data_dir" {
  default = "/opt/elasticsearch/data"
}

variable "elasticsearch_logs_dir" {
  default = "/var/log/elasticsearch"
}

variable "data_heap_size" {
  type = "string"
  default = "8g"
}

variable "master_heap_size" {
  type = "string"
  default = "2g"
}

variable "client_heap_size" {
  type = "string"
  default = "1g"
}
variable "security_enabled" {
  description = "Whether or not to enable x-pack security on the cluster"
  default = "false"
}

variable "monitoring_enabled" {
  description = "Whether or not to enable x-pack monitoring on the cluster"
  default = "true"
}

variable "xpack_monitoring_host" {
  description = "ES host to send monitoring data"
  default     = "self"
}