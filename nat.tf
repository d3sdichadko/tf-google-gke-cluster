resource "google_compute_router" "gke" {
  name    = "gke-router"
  region  = var.GOOGLE_REGION
  network = google_compute_network.gke.id
}

resource "google_compute_router_nat" "gke" {
  name   = "gke-nat"
  router = google_compute_router.gke.name
  region = google_compute_router.gke.region

  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name = google_compute_subnetwork.gke.id

    source_ip_ranges_to_nat = [
      "ALL_IP_RANGES"
    ]
  }
}
