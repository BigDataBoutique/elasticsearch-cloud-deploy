### MANDATORY ###
variable "iam_profile" {
  description = "Elasticsearch IAM profile"
}

variable "es_cluster" {
  description = "Name of the elasticsearch cluster, used in node discovery"
}

variable "aws_region" {
  type = "string"
  default = "us-east-1"
}

variable "availability_zones" {
  description = "AWS region to launch servers."
  default = "us-east-1a,us-east-1c,us-east-1d"
}

variable "environment" {
  default = "default"
}

variable "elasticsearch_instance_type" {
  type = "string"
  default = "c4.2xlarge"
}

variable "elasticsearch_volume_size" {
  type = "string"
  default = "100" # gb
}

variable "volume_name" {
  default = "/dev/sdh"
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
variable "heap_size" {
  default = "2g"
}

variable "elasticsearch_ami_id" {
  type = "string"
}

variable "masters_count" {
  default = "1" # temp until we split the launch configs
}

variable "datas_count" {
  default = "1"
}

# the ability to add additional existing security groups. In our case
# we have consul running as agents on the box
variable "additional_security_groups" {
  default = ""
}