# IBM VPC Subnets

Terraform module to provision subnets for an existing VPC. The number of subnets created depends on the value provided for `_count`. The created subnets will be named after the vpc with a suffix based on the value provided for `label`. Optionally, if values are provided for `gateways` then the subnets will be created with a public gateway.

## Software dependencies

The module depends on the following software components:

### Command-line tools

- terraform - v13
- kubectl

### Terraform providers

- IBM Cloud provider >= 1.22.0
- Helm provider >= 1.1.1 (provided by Terraform)

## Module dependencies

This module makes use of the output from other modules:

- Resource Group - github.com/cloud-native-toolkit/terraform-ibm-container-platform.git
- VPC - github.com/cloud-native-toolkit/terraform-ibm-vpc.git
- Gateway - github.com/cloud-native-toolkit/terraform-ibm-vpc-gateways.git

## Example usage

```hcl-terraform
module "dev_subnet" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc-subnets.git?ref=v1.0.3"
  
  resource_group_id   = module.resource_groups.id
  vpc_name            = module.vpc.name
  acl_id              = module.vpc.acl_id
  gateways            = module.gateways.gateways
  subnets             = var.subnets
  region              = var.region
  label               = var.label
  ibmcloud_api_key    = var.ibmcloud_api_key
```

## Module Variables

Name              | Type                                       | Description                                                                                                     | Sensitive | Default
----------------- | ------------------------------------------ | --------------------------------------------------------------------------------------------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------
region            | string                                     | The IBM Cloud region where the cluster will be/has been installed.                                              |           | 
ibmcloud_api_key  | string                                     | The IBM Cloud api token                                                                                         | true      | 
resource_group_id | string                                     | The id of the IBM Cloud resource group where the VPC has been provisioned.                                      |           | 
vpc_name          | string                                     | The name of the vpc instance                                                                                    |           | 
acl_id            | string                                     | Optional. Use existing ACL for subnets                                                                          |           | 
gateways          | list(object({id = string, zone = string})) | List of gateway ids and zones                                                                                   |           | []
label             | string                                     | Label for the subnets created                                                                                   |           | default
subnets           |                                            | A map describing the subnets to be provisioned. Lists can contain IPV4 CIDR Blocks or total ipv4 address counts |           | {<br>zone-1 = [<br>"10.10.10.0/24",<br>256<br>],<br>zone-2 = [<br>"10.40.10.0/24"<br>],<br>zone-3 = [<br>"10.70.10.0/24"<br>]<br>}
subnet_data       | list(string)                               | A list of subnets to get from a data block. Conflicts with `subnets`.                                           |           | []
acl_rules         |                                            | List of rules to set on the subnet access control list. Conflicts with `acl_id`                                 |           | []

## Module Outputs

Name     | Description
-------- | ------------------------------------------------------
count    | The number of subnets created
ids      | The ids of the created subnets
names    | The ids of the created subnets
subnets  | The subnets that were created
acl_id   | The id of the network acl for the subnets
vpc_name | The name of the VPC where the subnets were provisioned
vpc_id   | The id of the VPC where the subnets were provisioned