
locals {
  zone_count         = 3
  vpc_zone_names     = [ for index in range(var._count): "${var.region}-${(index % local.zone_count) + 1}" ]
  gateway_count      = min(length(var.gateways), local.zone_count)
  ipv4_cidr_provided = length(var.ipv4_cidr_blocks) >= var._count
  ipv4_cidr_block    = local.ipv4_cidr_provided ? var.ipv4_cidr_blocks : [ for index in range(var._count): "" ]
  name_prefix        = "${var.vpc_name}-subnet-${var.label}"
  subnet_output      = var.provision ? (local.ipv4_cidr_provided ? ibm_is_subnet.vpc_subnet_cidr_block : ibm_is_subnet.vpc_subnet_total_count) : data.ibm_is_subnet.vpc_subnet
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

data ibm_is_vpc vpc {
  depends_on = [null_resource.print_names]

  name  = var.vpc_name
}

resource ibm_is_subnet vpc_subnet_total_count {
  count                    = var.provision && !local.ipv4_cidr_provided ? var._count : 0

  name                     = "${local.name_prefix}${format("%02s", count.index)}"
  zone                     = local.vpc_zone_names[count.index]
  vpc                      = data.ibm_is_vpc.vpc.id
  public_gateway           = coalesce([ for gateway in var.gateways: gateway.id if gateway.zone == local.vpc_zone_names[count.index] ]...)
  total_ipv4_address_count = var.ipv4_address_count
  resource_group           = var.resource_group_id
  network_acl              = var.acl_id
}

resource null_resource print_subnet_count_names {
  for_each = toset(ibm_is_subnet.vpc_subnet_total_count[*].name)

  provisioner "local-exec" {
    command = "echo 'Provisioned subnet: ${each.value}'"
  }
}


resource ibm_is_vpc_address_prefix cidr_prefix {
  count = var.provision && local.ipv4_cidr_provided ? var._count : 0

  name  = "${var.vpc_name}-cidr-${var.label}${format("%02s", count.index)}"
  zone  = local.vpc_zone_names[count.index]
  vpc   = data.ibm_is_vpc.vpc.id
  cidr  = local.ipv4_cidr_block[count.index]
}

resource ibm_is_subnet vpc_subnet_cidr_block {
  count           = var.provision && local.ipv4_cidr_provided ? var._count : 0
  depends_on      = [ibm_is_vpc_address_prefix.cidr_prefix]

  name            = "${local.name_prefix}${format("%02s", count.index)}"
  zone            = local.vpc_zone_names[count.index]
  vpc             = data.ibm_is_vpc.vpc.id
  public_gateway  = coalesce([ for gateway in var.gateways: gateway.id if gateway.zone == local.vpc_zone_names[count.index] ]...)
  resource_group  = var.resource_group_id
  network_acl     = var.acl_id
  ipv4_cidr_block = local.ipv4_cidr_block[count.index]
}

resource null_resource print_subnet_cidr_names {
  for_each = toset(ibm_is_subnet.vpc_subnet_cidr_block[*].name)

  provisioner "local-exec" {
    command = "echo 'Provisioned subnet: ${each.value}'"
  }
}

data ibm_is_subnet vpc_subnet {
  count = !var.provision ? var._count : 0
  depends_on = [null_resource.print_subnet_cidr_names, null_resource.print_subnet_count_names]

  name  = "${local.name_prefix}${format("%02s", count.index)}"
}
