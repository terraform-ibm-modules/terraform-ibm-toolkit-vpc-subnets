output "count" {
  description = "The number of subnets created"
  value       = var._count
}

output "subnets" {
  description = "The subnets that were created"
  value       = [ for subnet in local.subnet_output: {id = subnet.id, zone = subnet.zone, label = var.label} ]
}

output "security_group_id" {
  description = "The id of the security group created for the subnets"
  value       = local.security_group.id
}

output "security_group" {
  description = "The the security group created for the subnets"
  value       = local.security_group
}
