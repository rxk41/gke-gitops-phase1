variable "project_id" {
  type = string
}
variable "region" {
  type = string
}
variable "zone" {
  type = string
}
variable "cluster_name" {
  type = string
}
variable "network_name" {
  type = string
}
variable "subnetwork_name" {
  type = string
}
variable "node_count" {
  type = number
}
variable "machine_type" {
  type = string
}

variable "node_pool_name" {
  type = string
}


variable "disk_size_gb" {
  type    = number
}