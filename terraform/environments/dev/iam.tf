module "iam" {
  source                            = "../../modules/iam"
  project_id                        = var.project_id
  region                            = var.region
  github_repository                 = var.github_repository
  github_actions_service_account_id = var.github_actions_service_account_id
  gke_workload_service_account_id   = var.gke_workload_service_account_id
  artifact_repository_id            = var.artifact_repository_id
  sonar_secret_id                   = var.sonar_secret_id
  database_secret_id                = var.database_secret_id
  depends_on                        = [google_project_service.required, module.artifact_registry, module.secret_manager]
}
