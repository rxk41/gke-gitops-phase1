# Guarded on purpose. Do not enable until the existing cluster is imported and
# terraform plan shows no replacement or destructive changes.
module "gke" {
  source = "../../modules/gke"
  count = var.manage_gke_cluster ? 1 : 0
  project_id = var.project_id
  region = var.region
  zone = var.zone
  cluster_name = var.cluster_name
  network_name = var.create_network ? module.vpc[0].network_name : var.network_name
  subnetwork_name = var.create_network ? module.vpc[0].subnetwork_name : var.subnetwork_name
  node_pool_name = var.node_pool_name
  node_count = var.node_count
  machine_type = var.machine_type
  depends_on = [google_project_service.required, module.vpc]
}
