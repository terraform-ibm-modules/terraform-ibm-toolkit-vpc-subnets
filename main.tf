
locals {
  zone_count         = 3
  vpc_zone_names     = [ for index in range(var._count): "${var.region}-${((index + var.zone_offset) % local.zone_count) + 1}" ]
  gateway_count      = min(length(var.gateways), local.zone_count)
  name_prefix        = "${var.vpc_name}-subnet-${var.label}"
  subnet_output      = var.provision ? ibm_is_subnet.vpc_subnets : data.ibm_is_subnet.vpc_subnet
  ipv4_cidr_provided = length(var.ipv4_cidr_blocks) >= var._count
  ipv4_cidr_block    = local.ipv4_cidr_provided ? var.ipv4_cidr_blocks : [ for val in range(var._count): null ]
  total_ipv4_address_count = local.ipv4_cidr_provided ? null : var.ipv4_address_count
  default_acl_rules  = [{
    name = "allow-ingress-internal"
    action = "allow"
    direction = "inbound"
    source = "10.0.0.0/8"
    destination = "10.0.0.0/8"
  }, {
    name = "allow-roks-ingress"
    action = "allow"
    direction = "inbound"
    source = "166.8.0.0/14"
    destination = "10.0.0.0/8"
  }, {
    name = "allow-vse-ingress"
    action = "allow"
    direction = "inbound"
    source = "161.26.0.0/16"
    destination = "10.0.0.0/8"
  }, {
    name = "allow-egress-internal"
    action = "allow"
    direction = "outbound"
    source = "10.0.0.0/8"
    destination = "10.0.0.0/8"
  }, {
    name = "allow-roks-egress"
    action = "allow"
    direction = "outbound"
    source = "10.0.0.0/8"
    destination = "166.8.0.0/14"
  }, {
    name = "allow-vse-egress"
    action = "allow"
    direction = "outbound"
    source = "10.0.0.0/8"
    destination = "161.26.0.0/16"
  }]
  acl_rules = concat(local.default_acl_rules, var.acl_rules)
  vpc_id = data.ibm_is_vpc.vpc.id
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = distinct(concat(var.common_tags, var.tags))
}

resource null_resource print_names {
  provisioner "local-exec" {
    command = "echo 'VPC name: ${var.vpc_name != null ? var.vpc_name : "null"}'"
  }
  provisioner "local-exec" {
    command = "echo 'IPv4 address count: ${var.ipv4_address_count}'"
  }
  provisioner "local-exec" {
    command = "echo 'IPv4 cidr blocks: ${jsonencode(local.ipv4_cidr_block)}'"
  }
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_name}'"
  }
}

data ibm_resource_group resource_group {
  depends_on = [null_resource.print_names]

  name = var.resource_group_name
}

data ibm_is_vpc vpc {
  depends_on = [null_resource.print_names]

  name = var.vpc_name
}

resource ibm_is_network_acl subnet_acl {
  count = var.provision ? 1 : 0

  name = local.name_prefix
  vpc  = local.vpc_id
  resource_group = local.resource_group_id
}

resource ibm_is_network_acl_rule acl_rule {
  count = var.provision ? length(local.acl_rules) : 0

  network_acl = var.provision ? ibm_is_network_acl.subnet_acl[0].id : ""

  name        = substr("${local.name_prefix}-${local.acl_rules[count.index]["name"]}", 0, 63)
  action      = local.acl_rules[count.index]["action"]
  direction   = local.acl_rules[count.index]["direction"]
  source      = local.acl_rules[count.index]["source"]
  destination = local.acl_rules[count.index]["destination"]

  dynamic "tcp" {
    for_each = lookup(local.acl_rules[count.index], "tcp", null) != null ? [ lookup(local.acl_rules[count.index], "tcp", null) ] : []

    content {
      port_min = tcp.value["port_min"]
      port_max = tcp.value["port_max"]
      source_port_min = tcp.value["source_port_min"]
      source_port_max = tcp.value["source_port_max"]
    }
  }

  dynamic "udp" {
    for_each = lookup(local.acl_rules[count.index], "udp", null) != null ? [ lookup(local.acl_rules[count.index], "udp", null) ] : []

    content {
      port_min = udp.value["port_min"]
      port_max = udp.value["port_max"]
      source_port_min = udp.value["source_port_min"]
      source_port_max = udp.value["source_port_max"]
    }
  }

  dynamic "icmp" {
    for_each = lookup(local.acl_rules[count.index], "icmp", null) != null ? [ lookup(local.acl_rules[count.index], "icmp", null) ] : []

    content {
      type = icmp.value["type"]
      code = lookup(icmp.value, "code", null)
    }
  }
}

resource ibm_is_subnet vpc_subnets {
  count                    = var.provision ? var._count : 0

  name                     = "${local.name_prefix}${format("%02s", count.index + 1)}"
  zone                     = local.vpc_zone_names[count.index]
  vpc                      = local.vpc_id
  public_gateway           = local.gateway_count == 0 ? null : coalesce([ for gateway in var.gateways: gateway.id if gateway.zone == local.vpc_zone_names[count.index] ]...)
  total_ipv4_address_count = local.total_ipv4_address_count
  ipv4_cidr_block          = local.ipv4_cidr_block[count.index]
  resource_group           = local.resource_group_id
  network_acl              = var.provision ? ibm_is_network_acl.subnet_acl[0].id : null
  tags                     = local.tags
}

data ibm_is_subnet vpc_subnet {
  count = !var.provision ? var._count : 0

  name  = "${local.name_prefix}${format("%02s", count.index + 1)}"
}
