module "subnets" {
  source = "./module"

  resource_group_id  = module.resource_group.id
  region             = var.region
  vpc_name           = module.vpc.name
  gateways           = module.gateways.gateways
  _count             = var.vpc_subnet_count
  label              = "cluster"
  ipv4_cidr_blocks   = jsondecode(var.ipv4_cidr_blocks)
  ipv4_address_count = var.ipv4_address_count
  acl_rules          = [{
    name="ingress-ssh"
    action="allow"
    direction="inbound"
    source="0.0.0.0/0"
    destination="10.0.0.0/8"
    tcp = {
      port_min=22
      port_max=22
      source_port_min=22
      source_port_max=22
    }
  }, {
    name="egress-ssh"
    action="allow"
    direction="outbound"
    destination="0.0.0.0/0"
    source="10.0.0.0/8"
    tcp = {
      port_min=22
      port_max=22
      source_port_min=22
      source_port_max=22
    }
  }]
}
