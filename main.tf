
locals {
  zone_count        = 3
  vpc_zone_names    = [ for index in range(var._count): "${var.region}-${(index % local.zone_count) + 1}" ]
  gateway_count     = min(length(var.gateways), local.zone_count)
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
  public_gateway           = coalesce([ for gateway in var.gateways: gateway.id if gateway.zone == local.vpc_zone_names[count.index] ]...)
  total_ipv4_address_count = 256
  resource_group           = var.resource_group_id
  network_acl              = var.acl_id
}
