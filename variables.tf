# Resource Group Variables
variable "resource_group_id" {
  type        = string
  description = "The id of the IBM Cloud resource group where the VPC has been provisioned."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the cluster will be/has been installed."
}

variable "vpc_name" {
  type        = string
  description = "The name of the vpc instance"
}

variable "zone_offset" {
  type        = number
  description = "The offset for the zone where the subnet should be created. The default offset is 0 which means the first subnet should be created in zone xxx-1"
  default     = 0
}

variable "_count" {
  type        = number
  description = "The number of subnets that should be provisioned"
  default     = 3
}

variable "label" {
  type        = string
  description = "Label for the subnets created"
  default     = "default"
}

variable "gateways" {
  type        = list(object({id = string, zone = string}))
  description = "List of gateway ids and zones"
  default     = []
}

variable "ipv4_cidr_blocks" {
  type        = list(string)
  description = "List of ipv4 cidr blocks for the subnets that will be created (e.g. ['10.10.10.0/24']). If you are providing cidr blocks then a value must be provided for each of the subnets. If you don't provide cidr blocks for each of the subnets then values will be generated using the {ipv4_address_count} value."
  default     = []
}

variable "ipv4_address_count" {
  type        = number
  description = "The size of the ipv4 cidr block that should be allocated to the subnet. If {ipv4_cidr_blocks} are provided then this value is ignored."
  default     = 256
}

variable "provision" {
  type        = bool
  description = "Flag indicating that the subnet should be provisioned. If 'false' then the subnet will be looked up."
  default     = true
}

variable "acl_rules" {
   type = list(object({
     name=string,
     action=string,
     direction=string,
     source=string,
     destination=string,
     tcp=optional(object({
       port_min=number,
       port_max=number,
       source_port_min=number,
       source_port_max=number
     })),
     udp=optional(object({
       port_min=number,
       port_max=number,
       source_port_min=number,
       source_port_max=number
     })),
     icmp=optional(object({
       type=number,
       code=optional(number)
     })),
   }))
  description = "List of rules to set on the subnet access control list"
  default = []
}
