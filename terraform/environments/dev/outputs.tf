output "project_id" {
  value = var.project_id
}
output "cluster_name" {
  value = var.cluster_name
}
output "artifact_registry_repository" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_repository_id}"
}
output "network_name" {
  value = var.create_network ? try(module.vpc[0].network_name, null) : var.network_name
}
output "subnetwork_name" {
  value = var.create_network ? try(module.vpc[0].subnetwork_name, null) : var.subnetwork_name
}
output "github_actions_service_account" {
  value = module.iam.github_actions_service_account_email
}
output "gke_workload_service_account" {
  value = module.iam.gke_workload_service_account_email
}
output "workload_identity_provider" {
  value = module.iam.workload_identity_provider_name
}
output "secret_ids" {
  value = module.secret_manager.secret_ids
}
