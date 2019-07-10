// Find the latest available AMI for Elasticsearch
data "aws_ami" "elasticsearch" {
  filter {
    name = "state"
    values = ["available"]
  }
  filter {
    name = "tag:ImageType"
    values = ["elasticsearch7-packer-image"]
  }
  most_recent = true
  owners = ["self"]
}

// Find the latest available AMI for the Kibana client node
data "aws_ami" "kibana_client" {
  filter {
    name = "state"
    values = ["available"]
  }
  filter {
    name = "tag:ImageType"
    values = ["kibana7-packer-image"]
  }
  most_recent = true
  owners = ["self"]
}
