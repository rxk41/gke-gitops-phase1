module "vpc" {
  depends_on = [google_project_service.required]
  source = "../../modules/vpc"
  count = var.create_network ? 1 : 0
  project_id = var.project_id
  network_name = var.network_name
  subnetwork_name = var.subnetwork_name
  region = var.region
  subnet_cidr = var.subnet_cidr
  pods_cidr = var.pods_cidr
  services_cidr = var.services_cidr
}
