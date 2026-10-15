resource "google_secret_manager_secret" "this" {
  for_each = toset(var.secret_ids)
  project = var.project_id
  secret_id = each.value
  replication {
    auto {}
  }
  labels = { managed-by = "terraform", purpose = "gke-gitops-lab" }
}
