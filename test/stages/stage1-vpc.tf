module "vpc" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc.git"

  resource_group_id   = module.resource_group.id
  resource_group_name = module.resource_group.name
  region              = var.region
  name_prefix         = var.name_prefix
  ibmcloud_api_key    = var.ibmcloud_api_key
  address_prefix_count = var.address_prefix_count
  address_prefixes = tolist(setsubtract(split(",", var.address_prefixes), [""]))
}
