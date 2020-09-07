### MANDATORY ###
variable "es_cluster" {
  description = "Name of the elasticsearch cluster, used in node discovery"
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  description = "VPC ID to create the Elasticsearch cluster in"
  type        = string
}

variable "clients_subnet_ids" {
  description = "Subnets to run client nodes in, defined as avalabilityZone -> subnets mapping. Will autofill to all available subnets in AZ when left empty."
  type        = map(list(string))
  default     = {}
}

variable "cluster_subnet_ids" {
  description = "Subnets to run cluster nodes in, defined as avalabilityZone -> subnets mapping. Will autofill to all available subnets in AZ when left empty."
  type        = map(list(string))
  default     = {}
}

variable "key_name" {
  description = "Key name to be used with the launched EC2 instances."
  default     = "elasticsearch"
}

variable "environment" {
  default = "default"
}

variable "data_instance_type" {
  type    = string
  default = "c5.2xlarge"
}

variable "master_instance_type" {
  type    = string
  default = "c5.large"
}

variable "elasticsearch_volume_size" {
  type    = string
  default = "100" # gb
}

variable "volume_encryption" {
  default = true
}

variable "elasticsearch_data_dir" {
  default = "/opt/elasticsearch/data"
}

variable "elasticsearch_logs_dir" {
  default = "/var/log/elasticsearch"
}

# default elasticsearch heap size
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

variable "masters_count" {
  type        = map(number)
  default     = {}
  description = "Master nodes count per avalabilityZone. If all node counts are empty, will run in singlenode mode."
}

variable "datas_count" {
  type        = map(number)
  default     = {}
  description = "Data nodes count per avalabilityZone. If all node counts are empty, will run in singlenode mode."
}

variable "clients_count" {
  type        = map(number)
  default     = {}
  description = "Client nodes count per avalabilityZone. If all node counts are empty, will run in singlenode mode."
}

variable "security_enabled" {
  description = "Whether or not to enable x-pack security on the cluster"
  default     = false
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

# the ability to add additional existing security groups. In our case
# we have consul running as agents on the box
variable "additional_security_groups" {
  type    = list(string)
  default = []
}

variable "ebs_optimized" {
  description = "Whether data instances are EBS optimized or not"
  default     = "true"
}

variable "xpack_monitoring_host" {
  description = "ES host to send monitoring data"
  default     = "http://localhost:9200/"
}

variable "filebeat_monitoring_host" {
  description = "ES host to send filebeat data"
  default     = ""
}

variable "s3_backup_bucket" {
  description = "S3 bucket for backups"
  default     = ""
}

variable "alb_subnets" {
  description = "Subnets to run the ALB in. Defaults to all VPC subnets."
  default     = []
}

variable "singlenode_az" {
  description = "This variable is required when running in singlenode mode. Singlenode mode is enabled when masters_count, datas_count and clients_count are all empty,"
  default     = ""
}

variable "bootstrap_node_subnet_id" {
  description = "Use to override which subnet the bootstrap node is created in."
  default     = ""
}

variable "use_g1gc" {
  description = "Whether or not to enable G1GC in jvm.options ES config"
  default     = false
}

variable "DEV_MODE_scripts_s3_bucket" {
  description = "S3 bucket to override init scripts from. Should not be used on production."
  default     = ""
}
