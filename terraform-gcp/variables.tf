### MANDATORY ###
variable "es_cluster" {
  description = "Name of the elasticsearch cluster, used in node discovery"
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_credentials_path" {
  type    = string
  default = ""
}

variable "gcp_zone" {
  type    = string
  default = "us-central1-a"
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

variable "environment" {
  default = "default"
}

variable "masters_count" {
  type        = map(number)
  default     = {}
  description = "Master nodes count per GCP zone. If all node counts are empty, will run in singlenode mode."
}

variable "datas_count" {
  type        = map(number)
  default     = {}
  description = "Data nodes count per GCP zone. If all node counts are empty, will run in singlenode mode."
}

variable "data_voters_count" {
  type        = map(number)
  default     = {}
  description = "Data nodes count per GCP zone. If all node counts are empty, will run in singlenode mode."
}

variable "clients_count" {
  type        = map(number)
  default     = {}
  description = "Client nodes count per GCP zone. If all node counts are empty, will run in singlenode mode."
}

variable "security_enabled" {
  description = "Whether or not to enable x-pack security on the cluster"
  default     = true
}

variable "singlenode_zone" {
  description = "This variable is required when running in singlenode mode. Singlenode mode is enabled when masters_count, datas_count and clients_count are all empty,"
  default     = ""
}

variable "monitoring_enabled" {
  description = "Whether or not to enable x-pack monitoring on the cluster"
  default     = "true"
}

variable "client_user" {
  description = "The username to use when setting up basic auth on Grafana and Cerebro."
  default     = "elastic"
}

variable "public_facing" {
  description = "Whether or not the created cluster should be accessible from the public internet"
  type        = bool
  default     = true
}

variable "gcs_snapshots_bucket" {
  description = "GCS bucket for backups"
  default     = ""
}

variable "cluster_network" {
  default = "default"
}

variable "master_machine_type" {
  default = "n1-standard-1"
}

variable "data_machine_type" {
  default = "n1-standard-4"
}

variable "elasticsearch_volume_size" {
  type    = string
  default = "100" # gb
}

variable "elasticsearch_data_dir" {
  default = "/opt/elasticsearch/data"
}

variable "elasticsearch_logs_dir" {
  default = "/var/log/elasticsearch"
}

variable "data_heap_size" {
  type    = string
  default = "8g"
}

variable "master_heap_size" {
  type    = string
  default = "2g"
}

variable "client_heap_size" {
  type    = string
  default = "1g"
}

variable "xpack_monitoring_host" {
  description = "ES host to send monitoring data"
  default     = "http://localhost:9200"
}

variable "filebeat_monitoring_host" {
  description = "ES host to send filebeat data"
  default     = ""
}

variable "use_g1gc" {
  description = "Whether or not to enable G1GC in jvm.options ES config. . Left in for backwards compatibility, deployments with Elasticsearch 7.7 and above should not use this."
  default     = false
}

variable "DEV_MODE_scripts_gcs_bucket" {
  description = "GCS bucket to override init scripts from. Should not be used on production."
  default     = ""
}

variable "gcp_ssh_pub_key_file" {
  default = "id_rsa.pub"
}


variable "enable_direct_data_access" {
  default     = false
  description = "Enable attaching load balancer directly to data nodes"
}

variable "requires_bootstrapping" {
  description = "Overrides cluster bootstrap state"
  default     = true
}

variable "log_size" {
  description = "Retained log4j log size in MB"
  default     = "128"
}

variable "log_level" {
  description = "log4j log level"
  default     = "INFO"
}

variable "auto_shut_down_bootstrap_node" {
  description = "disable to prevent bootstrap node from shutting down"
  default = true
}
