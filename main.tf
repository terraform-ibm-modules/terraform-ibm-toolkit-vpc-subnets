
locals {
  zone_count        = 3
  vpc_zone_names    = [ for index in range(var._count): "${var.region}-${(index % local.zone_count) + 1}" ]
  gateway_count     = min(length(var.gateway_ids), local.zone_count)
  security_group_id = data.ibm_is_vpc.vpc.default_security_group
}

resource null_resource print_names {
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_id}'"
  }
  provisioner "local-exec" {
    command = "echo 'VPC name: ${var.vpc_name}'"
  }
}

data ibm_is_vpc vpc {
  depends_on = [null_resource.print_names]

  name  = var.vpc_name
}

resource ibm_is_subnet vpc_subnet {
  count                    = var._count

  name                     = "${var.vpc_name}-subnet-${var.label}${format("%02s", count.index)}"
  zone                     = local.vpc_zone_names[count.index]
  vpc                      = data.ibm_is_vpc.vpc.id
  public_gateway           = var.gateway_ids[count.index % local.gateway_count]
  total_ipv4_address_count = 256
  resource_group           = var.resource_group_id
  network_acl              = var.acl_id
}

resource ibm_is_security_group_rule rule_icmp_ping {
  group     = local.security_group_id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  icmp {
    type = 8
  }
}

# from https://cloud.ibm.com/docs/vpc?topic=vpc-service-endpoints-for-vpc
resource ibm_is_security_group_rule "cse_dns_1" {
  group     = local.security_group_id
  direction = "outbound"
  remote    = "161.26.0.10"
  udp {
    port_min = 53
    port_max = 53
  }
}

resource ibm_is_security_group_rule cse_dns_2 {
  group     = local.security_group_id
  direction = "outbound"
  remote    = "161.26.0.11"
  udp {
    port_min = 53
    port_max = 53
  }
}

resource ibm_is_security_group_rule private_dns_1 {
  group     = local.security_group_id
  direction = "outbound"
  remote    = "161.26.0.7"
  udp {
    port_min = 53
    port_max = 53
  }
}

resource ibm_is_security_group_rule private_dns_2 {
  group     = local.security_group_id
  direction = "outbound"
  remote    = "161.26.0.8"
  udp {
    port_min = 53
    port_max = 53
  }
}
