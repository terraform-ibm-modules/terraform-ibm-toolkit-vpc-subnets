module "subnets" {
  source = "./module"

  resource_group_id  = module.resource_group.id
  region             = var.region
  ibmcloud_api_key   = var.ibmcloud_api_key
  vpc_name           = module.vpc.name
  vpc_id             = module.vpc.id
  gateways           = module.gateways.gateways
  _count             = var.vpc_subnet_count
  label              = "cluster"
  ipv4_cidr_blocks   = jsondecode(var.ipv4_cidr_blocks)
  ipv4_address_count = var.ipv4_address_count
  auth_id             = module.flow-log-auth.id
  flow_log_cos_bucket_name = module.dev_cos_bucket.bucket_name
}
