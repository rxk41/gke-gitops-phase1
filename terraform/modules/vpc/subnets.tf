resource "google_compute_subnetwork" "this" {
  project = var.project_id
  name = var.subnetwork_name
  region = var.region
  network = google_compute_network.this.id
  ip_cidr_range = var.subnet_cidr
  private_ip_google_access = true
  secondary_ip_range {
    range_name = "gke-pods"
    ip_cidr_range = var.pods_cidr
  }
  secondary_ip_range {
    range_name = "gke-services"
    ip_cidr_range = var.services_cidr
  }
}
