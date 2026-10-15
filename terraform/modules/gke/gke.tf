resource "google_container_cluster" "this" {
  project = var.project_id
  name = var.cluster_name
  location = var.zone
  network = var.network_name
  subnetwork = var.subnetwork_name
  deletion_protection = true
  remove_default_node_pool = true
  initial_node_count = 1
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name = "gke-pods"
    services_secondary_range_name = "gke-services"
  }
  release_channel { channel = "REGULAR" }
  workload_identity_config { workload_pool = "${var.project_id}.svc.id.goog" }
  addons_config {
    http_load_balancing { disabled = false }
    horizontal_pod_autoscaling { disabled = false }
  }
  lifecycle {
    prevent_destroy = true
    # Keep this module disabled until existing cluster configuration is reconciled.
  }
}
resource "google_container_node_pool" "primary" {
  project = var.project_id
  name = var.node_pool_name
  location = var.zone
  cluster = google_container_cluster.this.name
  node_count = var.node_count
  node_config {
    machine_type = var.machine_type
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    workload_metadata_config { mode = "GKE_METADATA" }
    labels = { workload = "general" }
  }
  management {
    auto_repair = true
    auto_upgrade = false
  }
  lifecycle {
    prevent_destroy = true
  }
}
