data "http" "my_public_ip" {
  url = "https://ifconfig.co/json"
  request_headers = {
    Accept = "application/json"
  }
}

locals {
  caller_ip = jsondecode(data.http.my_public_ip.body).ip
  caller_cidr = "${local.caller_ip}/32"
  cidr_blocks = var.cidr_blocks == [] ? [local.caller_cidr] : var.cidr_blocks
}