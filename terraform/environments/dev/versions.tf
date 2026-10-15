terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 6.0" }
  }
  # Configure a protected GCS backend before using this for shared state.
  # backend "gcs" { bucket = "YOUR-TF-STATE-BUCKET" prefix = "gke-lab/dev" }
}
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
