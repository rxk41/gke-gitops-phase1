module "artifact_registry" {
  depends_on = [google_project_service.required]
  source = "../../modules/artifact-registry"
  project_id = var.project_id
  region = var.region
  repository_id = var.artifact_repository_id
}
