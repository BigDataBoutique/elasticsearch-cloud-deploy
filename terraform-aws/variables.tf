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
  description = "Subnets to run client nodes and client ELB in. Only one subnet per availability zone allowed. Will detect a single subnet by default."
  type        = map(list(string))
  default     = {}
}

variable "cluster_subnet_ids" {
  description = "Cluster nodes subnets. Defaults to all VPC subnets."
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
  description = "masters count per AZ"
}

variable "datas_count" {
  type        = map(number)
  default     = {}
  description = "data nodes count per AZ"
}

variable "clients_count" {
  type        = map(number)
  default     = {}
  description = "client nodes count per AZ"
}

variable "security_enabled" {
  description = "Whether or not to enable x-pack security on the cluster"
  default     = "false"
}

variable "monitoring_enabled" {
  description = "Whether or not to enable x-pack monitoring on the cluster"
  default     = "true"
}

variable "client_user" {
  default = "elastic"
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

variable "lb_port" {
  description = "The port the load balancer should listen on for API requests."
  default     = 80
}

variable "health_check_type" {
  description = "Controls how health checking is done. Must be one of EC2 or ELB."
  default     = "EC2"
}

variable "xpack_monitoring_host" {
  description = "ES host to send monitoring data"
  default     = "self"
}

variable "s3_backup_bucket" {
  description = "S3 bucket for backups"
  default     = ""
}

variable "alb_subnets" {
  default = []
}

variable "singlenode_az" {
  default = ""
}

variable "bootstrap_node_subnet_id" {
  default = ""
}