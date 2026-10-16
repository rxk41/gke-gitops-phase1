module "secret_manager" {
  depends_on = [google_project_service.required]
  source     = "../../modules/secret-manager"
  project_id = var.project_id
  secret_ids = [var.sonar_secret_id, var.database_secret_id]
}
