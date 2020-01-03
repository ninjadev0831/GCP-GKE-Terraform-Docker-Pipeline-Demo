terraform {
  source = "../../../..//modules/gcp/k8s-cluster/"
}

dependency "gcp-project" {
  config_path = "../../../common/gcp/project"
}

inputs = {
  terraform_sa_fqdn = dependency.gcp-project.outputs.terraform_sa_fqdn
  environment = "prod"
  master_cidr = "172.16.0.0/28"
  subnet_primary_ip_range = "172.20.0.0/20"
  subnet_services_ip_range = "172.20.16.0/20"
  subnet_pods_ip_range = "10.8.0.0/14"
  region = "europe-west4"
  zones = ["europe-west4-a", "europe-west4-b", "europe-west4-c"]
}
