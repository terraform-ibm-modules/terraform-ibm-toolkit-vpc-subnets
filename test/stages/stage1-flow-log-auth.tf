module "flow-log-auth" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-iam-service-authorization"

  source_service_name = "is"
  source_resource_type = "flow-log-collector"
  provision = true
  target_service_name = "cloud-object-storage"
  target_resource_group_id = module.resource_group.id
  roles = ["Writer"]
}
