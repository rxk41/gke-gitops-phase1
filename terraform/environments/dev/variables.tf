variable "project_id" {
  type    = string
  default = "k8s-learning-510807"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "cluster_name" {
  type    = string
  default = "gke-istio-lab"
}

variable "network_name" {
  type    = string
  default = "gke-lab-vpc"
}

variable "subnetwork_name" {
  type    = string
  default = "gke-lab-us-central1"
}

variable "subnet_cidr" {
  type    = string
  default = "10.20.0.0/20"
}

variable "pods_cidr" {
  type    = string
  default = "10.24.0.0/14"
}

variable "services_cidr" {
  type    = string
  default = "10.28.0.0/20"
}

variable "node_count" {
  type    = number
  default = 3
}

variable "machine_type" {
  type    = string
  default = "e2-standard-4"
}

variable "artifact_repository_id" {
  type    = string
  default = "microservices"
}

variable "github_actions_service_account_id" {
  type    = string
  default = "github-actions-ci"
}

variable "gke_workload_service_account_id" {
  type    = string
  default = "store-workload"
}

variable "github_repository" {
  type    = string
  default = "rxk41/gke-gitops-phase1"
}

variable "sonar_secret_id" {
  type    = string
  default = "sonar-token"
}

variable "database_secret_id" {
  type    = string
  default = "store-postgres-password"
}

variable "billing_account_id" {
  type        = string
  default     = ""
  description = "Optional billing account ID."
}

variable "manage_project_billing" {
  type        = bool
  default     = false
  description = "Only enable after importing the existing project resource into state."
}

variable "create_network" {
  type        = bool
  default     = false
  description = "Keep false when adopting an existing cluster until its current VPC is confirmed."
}

variable "manage_gke_cluster" {
  type        = bool
  default     = false
  description = "Enable only after importing the existing cluster and matching all settings."
}

variable "node_pool_name" {
  type        = string
  default     = "default-pool"
  description = "Set to the exact existing GKE node-pool name before importing."
}


variable "disk_size_gb" {
  description = "Boot disk size in GB for each GKE node"
  type        = number
  default     = 20
}