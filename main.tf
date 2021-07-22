##############################################################################
# Local Variables
##############################################################################

locals {
  # Dynamicly get length from variables
  gateway_count       = min(length(var.gateways), length(keys(var.subnets)))
  name_prefix         = "${var.vpc_name}-${var.label}"
  use_data            = length(var.subnet_data) == 0 ? false : true
  subnet_output       = local.use_data ? data.ibm_is_subnet.vpc_subnet : ibm_is_subnet.vpc_subnets
  # Create list of subnets from object
  subnet_list         = flatten([
    # For each key in the object create an array
    for i in keys(var.subnets):
    # Each item in the list contains information about a single subnet
    [
      for j in var.subnets[i]:
      {
        zone       = index(keys(var.subnets), i) + 1                         # Zone 1, 2, or 3
        zone_name  = "${var.region}-${index(keys(var.subnets), i) + 1}"  # Contains region and zone
        # Check for regex of cidr block or if total ipv4 address count
        cidr       = can(regex("^(2[0-5][0-9]|1[0-9]{1,2}|[0-9]{1,2}).(2[0-5][0-9]|1[0-9]{1,2}|[0-9]{1,2}).(2[0-5][0-9]|1[0-9]{1,2}|[0-9]{1,2}).(2[0-5][0-9]|1[0-9]{1,2}|[0-9]{1,2})\\/(3[0-2]|2[0-9]|1[0-9]|[0-9])$", j)) ? j : null
        ipv4_count = !can(regex("^(2[0-5][0-9]|1[0-9]{1,2}|[0-9]{1,2}).(2[0-5][0-9]|1[0-9]{1,2}|[0-9]{1,2}).(2[0-5][0-9]|1[0-9]{1,2}|[0-9]{1,2}).(2[0-5][0-9]|1[0-9]{1,2}|[0-9]{1,2})\\/(3[0-2]|2[0-9]|1[0-9]|[0-9])$", j)) ? j : null
        count      = index(var.subnets[i], j) + 1                            # Count of the subnet within the zone
      }
    ]
  ])

  # Create Object of Prefixes to be created
  subnet_prefix_list = {
    for i in local.subnet_list:
    i.cidr => {
      zone_name = i.zone_name
    } if i.cidr != null
  }

  default_acl_rules        = [
    {
      name = "allow-ingress-internal"
      action = "allow"
      direction = "inbound"
      source = "10.0.0.0/8"
      destination = "10.0.0.0/8"
    }, 
    {
      name = "allow-egress-internal"
      action = "allow"
      direction = "outbound"
      source = "10.0.0.0/8"
      destination = "10.0.0.0/8"
    }, 
    {
      name = "allow-roks-egress"
      action = "allow"
      direction = "outbound"
      source = "10.0.0.0/8"
      destination = "166.8.0.0/14"
    }, 
    {
      name = "allow-vse-egress"
      action = "allow"
      direction = "outbound"
      source = "10.0.0.0/8"
      destination = "161.26.0.0/16"
    }, 
    {
      name = "allow-iaas-egress"
      action = "allow"
      direction = "outbound"
      source = "10.0.0.0/8"
      destination = "166.8.0.0/14"
    }
  ]
  acl_rules = concat(local.default_acl_rules, var.acl_rules)
}

##############################################################################


##############################################################################
# Print Names
##############################################################################

resource null_resource print_names {
  provisioner local-exec {
    command = "echo 'Resource group: ${var.resource_group_id != null ? var.resource_group_id : "null"}'"
  }
  provisioner local-exec {
    command = "echo 'VPC name: ${var.vpc_name != null ? var.vpc_name : "null"}'"
  }
  provisioner local-exec {
    command = "echo 'Subnets to be created: ${jsonencode(local.subnet_list)}'"
  }
}

##############################################################################


##############################################################################
# VPC Data
##############################################################################

data ibm_is_vpc vpc {
  depends_on = [null_resource.print_names]

  name = var.vpc_name
}

##############################################################################


##############################################################################
# ACL
##############################################################################

resource ibm_is_network_acl subnet_acl {
  count = local.use_data ? 0 : 1

  name           = local.name_prefix
  vpc            = data.ibm_is_vpc.vpc.id
  resource_group = var.resource_group_id

  dynamic rules {
    for_each = local.acl_rules

    content {
      name        = rules.value["name"]
      action      = rules.value["action"]
      direction   = rules.value["direction"]
      source      = rules.value["source"]
      destination = rules.value["destination"]

      dynamic tcp {
        for_each = lookup(rules.value, "tcp", null) != null ? [ lookup(rules.value, "tcp", null) ] : []

        content {
          port_min = tcp.value["port_min"]
          port_max = tcp.value["port_max"]
          source_port_min = tcp.value["source_port_min"]
          source_port_max = tcp.value["source_port_max"]
        }
      }

      dynamic udp {
        for_each = lookup(rules.value, "udp", null) != null ? [ lookup(rules.value, "udp", null) ] : []

        content {
          port_min = udp.value["port_min"]
          port_max = udp.value["port_max"]
          source_port_min = udp.value["source_port_min"]
          source_port_max = udp.value["source_port_max"]
        }
      }

      dynamic icmp {
        for_each = lookup(rules.value, "icmp", null) != null ? [ lookup(rules.value, "icmp", null) ] : []

        content {
          type = icmp.value["type"]
          code = lookup(icmp.value, "code", null)
        }
      }
    }
  }
}

##############################################################################


##############################################################################
# Create Subnet Address Prefixes
##############################################################################

resource ibm_is_vpc_address_prefix subnet_prefix {
  for_each = local.subnet_prefix_list
  name    = "${local.name_prefix}-prefix-${index(keys(local.subnet_prefix_list), each.key) + 1}" 
  zone    = each.value.zone_name
  vpc     = data.ibm_is_vpc.vpc.id
  cidr    = each.key
}

##############################################################################


##############################################################################
# Create Subnets
##############################################################################

resource ibm_is_subnet vpc_subnets {
  depends_on               = [ ibm_is_vpc_address_prefix.subnet_prefix ]
  count                    = local.use_data ? 0 : length(local.subnet_list)
  vpc                      = data.ibm_is_vpc.vpc.id
  name                     = "${local.name_prefix}-zone-${local.subnet_list[count.index].zone}-subnet-${local.subnet_list[count.index].count}"
  zone                     = local.subnet_list[count.index].zone_name
  resource_group           = var.resource_group_id
  total_ipv4_address_count = lookup(local.subnet_list[count.index], "ipv4_count", null)
  ipv4_cidr_block          = lookup(local.subnet_list[count.index], "cidr", null)
  network_acl              = var.acl_id == "" ? ibm_is_network_acl.subnet_acl[0].id : var.acl_id
  public_gateway           = length(var.gateways) == 0 ? null : coalesce(
    [ 
      for gateway in var.gateways: 
      gateway.id if gateway.zone == local.subnet_list[count.index].zone_name 
    ]...
  )
}

##############################################################################


##############################################################################
# Print Subnet Names
##############################################################################

resource null_resource print_subnet_names {
  for_each = toset(ibm_is_subnet.vpc_subnets[*].name)

  provisioner local-exec {
    command = "echo 'Provisioned subnet: ${each.value != null ? each.value : "null"}'"
  }
}

##############################################################################


##############################################################################
# Data Blocks if not provisioning
##############################################################################

data ibm_is_subnet vpc_subnet {
  count      = local.use_data ? length(var.subnet_data) : 0
  depends_on = [null_resource.print_subnet_names]

  name  = var.subnet_data[count.index]
}

##############################################################################