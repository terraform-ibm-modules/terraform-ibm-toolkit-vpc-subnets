module "subnets" {
  source = "./module"

  resource_group_id = module.resource_group.id
  region            = var.region
  ibmcloud_api_key  = var.ibmcloud_api_key
  vpc_name          = module.vpc.name
  acl_id            = module.vpc.acl_id
  gateway_ids       = module.gateways.ids
  count             = var.vpc_subnet_count
  label             = "cluster"
}
