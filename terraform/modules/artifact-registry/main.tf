resource "google_artifact_registry_repository" "docker" {
  project = var.project_id
  location = var.region
  repository_id = var.repository_id
  description = "Docker images for the GKE GitOps lab"
  format = "DOCKER"
  cleanup_policy_dry_run = true
}
