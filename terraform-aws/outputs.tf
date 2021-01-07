output "clients_dns" {
  value = aws_lb.elasticsearch-alb.*.dns_name
}

output "singlenode_ip" {
  value = local.singlenode_mode ? aws_network_interface.single_node.private_ip : ""

}

// Security group that has access to elasticsearch port 9200
// Used in single node mode where no load balancer has been configured
output "singlenode_es_access_sg" {
  value = aws_security_group.elasticsearch-alb-sg.id
}

output "vm_password" {
  value = random_string.vm-login-password.result
}

output "singlenode_az" {
  value = local.singlenode_subnet_id
}

output "cluster_subnet_ids" {
  value = jsonencode(local.cluster_subnet_ids)
}