# Resource Group Variables
variable "resource_group_id" {
  type        = string
  description = "The id of the IBM Cloud resource group where the VPC has been provisioned."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the cluster will be/has been installed."
}

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
}

variable "vpc_name" {
  type        = string
  description = "The name of the vpc instance"
}

variable "acl_id" {
  type        = string
  description = "The id of the network acl for the vpc instance"
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
  description = "List of ipv4 cidr blocks for the subnets that will be created (e.g. [\"10.10.10.0/24\"]). If you are providing cidr blocks then a value must be provided for each of the subnets. If you don't provide cidr blocks for each of the subnets then values will be generated using the {ipv4_address_count} value."
  default     = []
}

variable "ipv4_address_count" {
  type        = string
  description = "The size of the ipv4 cidr block that should be allocated to the subnet. If {ipv4_cidr_blocks} are provided then this value is ignored."
  default     = "256"
}
