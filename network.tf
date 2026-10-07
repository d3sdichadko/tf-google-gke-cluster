resource "google_compute_network" "gke" {
  name                    = "gke-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke" {
  name    = "gke-subnet"
  region  = var.GOOGLE_REGION
  network = google_compute_network.gke.id

  # Node VM addresses
  ip_cidr_range = "10.10.0.0/20"

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.30.0.0/20"
  }
}
