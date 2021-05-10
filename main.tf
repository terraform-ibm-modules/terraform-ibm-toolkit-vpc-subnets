
locals {
  zone_count         = 3
  vpc_zone_names     = [ for index in range(var._count): "${var.region}-${((index + var.zone_offset) % local.zone_count) + 1}" ]
  gateway_count      = min(length(var.gateways), local.zone_count)
  name_prefix        = "${var.vpc_name}-subnet-${var.label}"
  subnet_output      = var.provision ? ibm_is_subnet.vpc_subnets : data.ibm_is_subnet.vpc_subnet
  ipv4_cidr_provided = length(var.ipv4_cidr_blocks) >= var._count
  ipv4_cidr_block    = local.ipv4_cidr_provided ? [ for obj in var.ipv4_cidr_blocks: obj.cidr ] : [ for val in range(var._count): null ]
  total_ipv4_address_count = local.ipv4_cidr_provided ? null : var.ipv4_address_count
  default_acl_rules  = [{
    name = "ingress-http"
    action = "allow"
    direction = "inbound"
    source = "0.0.0.0/0"
    destination = "10.0.0.0/8"
    tcp = {
      port_min = 80
      port_max = 80
      source_port_min = 80
      source_port_max = 80
    }
  }, {
    name = "ingress-https"
    action = "allow"
    direction = "inbound"
    source = "0.0.0.0/0"
    destination = "10.0.0.0/8"
    tcp = {
      port_min = 443
      port_max = 443
      source_port_min = 443
      source_port_max = 443
    }
  }, {
    name = "ingress-DNS"
    action = "allow"
    direction = "inbound"
    source = "0.0.0.0/0"
    destination = "10.0.0.0/8"
    tcp = {
      port_min = 53
      port_max = 53
      source_port_min = 53
      source_port_max = 53
    }
  }, {
    name = "ingress-internal"
    action = "allow"
    direction = "inbound"
    source = "10.0.0.0/8"
    destination = "10.0.0.0/8"
  }, {
    name = "egress-http"
    action = "allow"
    direction = "outbound"
    destination = "0.0.0.0/0"
    source = "10.0.0.0/8"
    tcp = {
      port_min = 80
      port_max = 80
      source_port_min = 80
      source_port_max = 80
    }
  }, {
    name = "egress-https"
    action = "allow"
    direction = "outbound"
    destination = "0.0.0.0/0"
    source = "10.0.0.0/8"
    tcp = {
      port_min = 443
      port_max = 443
      source_port_min = 443
      source_port_max = 443
    }
  }, {
    name = "egress-DNS"
    action = "allow"
    direction = "outbound"
    destination = "0.0.0.0/0"
    source = "10.0.0.0/8"
    tcp = {
      port_min = 53
      port_max = 53
      source_port_min = 53
      source_port_max = 53
    }
  }, {
    name = "egress-internal"
    action = "allow"
    direction = "outbound"
    destination = "10.0.0.0/8"
    source = "10.0.0.0/8"
  }]
  acl_rules = concat(local.default_acl_rules, var.acl_rules)
}

resource null_resource print_names {
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_id}'"
  }
  provisioner "local-exec" {
    command = "echo 'VPC name: ${var.vpc_name}'"
  }
  provisioner "local-exec" {
    command = "echo 'IPv4 address count: ${var.ipv4_address_count}'"
  }
  provisioner "local-exec" {
    command = "echo 'IPv4 cidr blocks: ${jsonencode(local.ipv4_cidr_block)}'"
  }
}

resource ibm_is_network_acl subnet_acl {
  count = var.provision ? 1 : 0

  name = local.name_prefix
  vpc  = var.vpc_id

  dynamic "rules" {
    for_each = local.acl_rules

    content {
      name        = rules.value["name"]
      action      = rules.value["action"]
      direction   = rules.value["direction"]
      source      = rules.value["source"]
      destination = rules.value["destination"]

      dynamic "tcp" {
        for_each = lookup(rules.value, "tcp", null) != null ? [ lookup(rules.value, "tcp", null) ] : []

        content {
          port_min = tcp.value["port_min"]
          port_max = tcp.value["port_max"]
          source_port_min = tcp.value["source_port_min"]
          source_port_max = tcp.value["source_port_max"]
        }
      }

      dynamic "udp" {
        for_each = lookup(rules.value, "udp", null) != null ? [ lookup(rules.value, "udp", null) ] : []

        content {
          port_min = udp.value["port_min"]
          port_max = udp.value["port_max"]
          source_port_min = udp.value["source_port_min"]
          source_port_max = udp.value["source_port_max"]
        }
      }

      dynamic "icmp" {
        for_each = lookup(rules.value, "icmp", null) != null ? [ lookup(rules.value, "icmp", null) ] : []

        content {
          type = icmp.value["type"]
          code = icmp.value["code"] != null ? icmp.value["code"] : null
        }
      }
    }
  }
}

resource ibm_is_subnet vpc_subnets {
  count                    = var.provision ? var._count : 0

  name                     = "${local.name_prefix}${format("%02s", count.index)}"
  zone                     = local.vpc_zone_names[count.index]
  vpc                      = var.vpc_id
  public_gateway           = local.gateway_count == 0 ? null : coalesce([ for gateway in var.gateways: gateway.id if gateway.zone == local.vpc_zone_names[count.index] ]...)
  total_ipv4_address_count = local.total_ipv4_address_count
  ipv4_cidr_block          = local.ipv4_cidr_block[count.index]
  resource_group           = var.resource_group_id
  network_acl              = var.provision ? ibm_is_network_acl.subnet_acl[0].id : null
}

resource null_resource print_subnet_names {
  for_each = toset(ibm_is_subnet.vpc_subnets[*].name)

  provisioner "local-exec" {
    command = "echo 'Provisioned subnet: ${each.value}'"
  }
}

data ibm_is_subnet vpc_subnet {
  count = !var.provision ? var._count : 0
  depends_on = [null_resource.print_subnet_names]

  name  = "${local.name_prefix}${format("%02s", count.index)}"
}
