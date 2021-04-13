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
