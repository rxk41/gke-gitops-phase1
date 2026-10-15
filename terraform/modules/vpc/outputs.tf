output "network_name" {
  value = google_compute_network.this.name
}
output "network_self_link" {
  value = google_compute_network.this.self_link
}
output "subnetwork_name" {
  value = google_compute_subnetwork.this.name
}
output "subnetwork_self_link" {
  value = google_compute_subnetwork.this.self_link
}
