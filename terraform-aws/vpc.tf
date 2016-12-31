module "vpc" {
  source = "github.com/terraform-community-modules/tf_aws_vpc?ref=v1.0.2"

  name = "elasticsearch-vpc"

  cidr = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = "true"

  azs = ["${split(",", var.availability_zones)}"]
}