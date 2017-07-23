### MANDATORY ###
variable "es_cluster" {
  description = "Name of the elasticsearch cluster, used in node discovery"
}

variable "aws_region" {
  type = "string"
  default = "us-east-1"
}

variable "vpc_cidr" {
  type = "string"
  default = "10.0.0.0/16"
}

variable "vpc_id" {
  description = "VPC ID to create the Elasticsearch cluster in"
  type = "string"
  default = ""
}


variable "vpc_subnets" {
  description = "VPC subnet IDs to create the Elasticsearch cluster in"
  type = "list"
  default = [""]
}

variable "availability_zones" {
  description = "AWS region to launch servers."
  default = "us-east-1a,us-east-1b,us-east-1d"
}

variable "key_name" {
  description = "Key name to be used with the launched EC2 instances."
  default = "elasticsearch"
}

variable "environment" {
  default = "default"
}

variable "data_instance_type" {
  type = "string"
  default = "c4.2xlarge"
}

variable "master_instance_type" {
  type = "string"
  default = "m4.large"
}

variable "elasticsearch_volume_size" {
  type = "string"
  default = "100" # gb
}

variable "volume_name" {
  default = "/dev/xvdh"
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
  type = "string"
  default = "7g"
}

variable "master_heap_size" {
  type = "string"
  default = "2g"
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

# whether or not to enable x-pack security on the cluster
variable "security_enabled" {
  default = "false"
}

# client nodes have nginx installed on them, these credentials are used for basic auth
variable "client_user" {
  default = "exampleuser"
}
variable "client_pwd" {
  default = "changeme"
}

# the ability to add additional existing security groups. In our case
# we have consul running as agents on the box
variable "additional_security_groups" {
  default = ""
}
