output "count" {
  description = "The number of subnets created"
  value       = var._count
}

output "subnets" {
  description = "The subnets that were created"
  value       = [ for subnet in local.subnets: {id = subnet.id, zone = subnet.zone, label = var.label} ]
}
