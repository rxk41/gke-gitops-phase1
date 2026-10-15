resource "google_compute_network" "this" {
  project = var.project_id
  name = var.network_name
  auto_create_subnetworks = false
  routing_mode = "REGIONAL"
}
