# Configure the Google Cloud provider
provider "google" {
  # The GCP project to use
  project = var.GOOGLE_PROJECT
  # The GCP region to deploy resources in
  region = var.GOOGLE_REGION
}

# Create the GKE (Google Kubernetes Engine) cluster
resource "google_container_cluster" "this" {
  # Name of the cluster
  name = var.GKE_CLUSTER_NAME
  # Location (region) for the cluster
  location = var.GOOGLE_ZONE
  # Set this to false
  deletion_protection = false

  network    = google_compute_network.gke.id
  subnetwork = google_compute_subnetwork.gke.id

  # Set initial node count (required, but will remove default pool)
  initial_node_count = 1
  # Remove default node pool to use custom node pools instead
  remove_default_node_pool = true

  networking_mode = "VPC_NATIVE"

  # Make cluster VPC-native / IP-alias based
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  # Nodes get PRIVATE IP addresses only
  private_cluster_config {
    enable_private_nodes = true

    # Keep Kubernetes API reachable from Internet
    enable_private_endpoint = false

    master_ipv4_cidr_block = "172.16.0.0/28"
  }

  # Workload Identity configuration for GKE
  workload_identity_config {
    workload_pool = "${var.GOOGLE_PROJECT}.svc.id.goog"
  }

  # Node configuration for metadata
  node_config {
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# Create a custom node pool for the GKE cluster
resource "google_container_node_pool" "this" {
  # Name of the node pool
  name = var.GKE_POOL_NAME
  # GCP project to use (derived from the cluster)
  project = google_container_cluster.this.project
  # Attach node pool to the created cluster
  cluster = google_container_cluster.this.name
  # Location (region)
  location = google_container_cluster.this.location
  # Number of nodes in the pool
  node_count = var.GKE_NUM_NODES

  network_config {
    enable_private_nodes = true
  }

  node_config {
    machine_type = var.GKE_MACHINE_TYPE

    disk_type    = "pd-standard"
    disk_size_gb = 20

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# Module to authenticate with GKE cluster using native Terraform module
module "gke_auth" {
  depends_on = [
    google_container_cluster.this
  ]
  # Source of the module (Terraform Registry)
  source  = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version = ">= 24.0.0"
  # Project and cluster details for authentication
  project_id   = var.GOOGLE_PROJECT
  cluster_name = google_container_cluster.this.name
  location     = var.GOOGLE_ZONE
}

# Data source to retrieve the current Google client configuration
data "google_client_config" "current" {}

# Data source to fetch details about the created GKE cluster
data "google_container_cluster" "main" {
  # Name of the cluster
  name = google_container_cluster.this.name
  # Location (region)
  location = var.GOOGLE_ZONE
}
