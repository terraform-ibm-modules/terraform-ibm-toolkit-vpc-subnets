module "gateways" {
  source = "github.com/terraform-ibm-modules/terraform-ibm-toolkit-vpc-gateways.git"

  resource_group_id = module.resource_group.id
  region            = var.region
  vpc_name          = module.vpc.name
  common_tags       = var.common_tags
  tags              = ["test", "vpc_gateway"]
}
