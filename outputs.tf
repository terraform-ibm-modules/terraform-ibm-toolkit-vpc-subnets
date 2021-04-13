output "subnet_count" {
  description = "The number of subnets created"
  value       = var.subnet_count
}

output "subnets" {
  description = "The subnets that were created"
  value       = [ for subnet in ibm_is_subnet.vpc_subnet: {id = subnet.id, zone = subnet.zone, label = var.subnet_label} ]
}
