module "vpc" {
  source = "github.com/terraform-ibm-modules/terraform-ibm-toolkit-vpc.git"

  resource_group_name = module.resource_group.name
  region              = var.region
  name_prefix         = var.name_prefix
  address_prefix_count = var.address_prefix_count
  address_prefixes = jsondecode(var.address_prefixes)
  common_tags      = var.common_tags
  tags             = ["test", "vpc"]
}
