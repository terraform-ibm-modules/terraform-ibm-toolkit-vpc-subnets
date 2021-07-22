##############################################################################
# Provider Variables
##############################################################################

variable region {
  type        = string
  description = "The IBM Cloud region where the cluster will be/has been installed."
}

variable ibmcloud_api_key {
  sensitive   = true
  type        = string
  description = "The IBM Cloud api token"
}

##############################################################################


##############################################################################
# Resource Group Variables
##############################################################################

variable resource_group_id {
  type        = string
  description = "The id of the IBM Cloud resource group where the VPC has been provisioned."
}

##############################################################################


##############################################################################
# VPC Variables
##############################################################################

variable vpc_name {
  type        = string
  description = "The name of the vpc instance"
}

variable acl_id {
  type        = string
  description = "Optional. Use existing ACL for subnets"
  default     = ""
}

##############################################################################


##############################################################################
# Public Gateway Variables
##############################################################################

variable gateways {
  type        = list(object({id = string, zone = string}))
  description = "List of gateway ids and zones"
  default     = []
}

##############################################################################


##############################################################################
# Subnet Variables
##############################################################################

variable label {
  type        = string
  description = "Label for the subnets created"
  default     = "default"
}

variable subnets {
  description = "A map describing the subnets to be provisioned. Lists can contain IPV4 CIDR Blocks or total ipv4 address counts"
  default     = {
    # type = object({
    #   zone-1 = list(string)
    #   zone-2 = list(string)
    #   zone-3 = list(string)
    # })
    zone-1 = [
      "10.10.10.0/24",
      256
    ],

    zone-2 = [
      "10.40.10.0/24"
    ],

    zone-3 = [
      "10.70.10.0/24"
    ]
  }
}

variable subnet_data {
  description = "A list of subnets to get from a data block. Conflicts with `subnets`."
  type        = list(string)
  default     = []
}

variable acl_rules {
  # type = list(object({
  #   name=string,
  #   action=string,
  #   direction=string,
  #   source=string,
  #   destination=string,
  #   tcp=optional(object({
  #     port_min=number,
  #     port_max=number,
  #     source_port_min=number,
  #     source_port_max=number
  #   })),
  #   udp=optional(object({
  #     port_min=number,
  #     port_max=number,
  #     source_port_min=number,
  #     source_port_max=number
  #   })),
  #   icmp=optional(object({
  #     type=number,
  #     code=optional(number)
  #   })),
  # }))
  description = "List of rules to set on the subnet access control list. Conflicts with `acl_id`"
  default = []
}

##############################################################################
