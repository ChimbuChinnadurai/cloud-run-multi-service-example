resource "google_compute_network" "vpc_network" {
  name                    = "network-${var.name}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
  name          = "subnetwork-${var.name}"
  ip_cidr_range = "10.2.0.0/28"
  network       = google_compute_network.vpc_network.id
}

resource "google_vpc_access_connector" "connector" {
  name = "vpc-con-${var.name}"
  subnet {
    name = google_compute_subnetwork.network-with-private-secondary-ip-ranges.name
  }
}

resource "google_compute_global_address" "private_service_connect" {
  name         = "ip-psc-${var.name}"
  address_type = "INTERNAL"
  purpose      = "PRIVATE_SERVICE_CONNECT"
  network      = google_compute_network.vpc_network.id
  address      = "10.43.0.1"
}

resource "google_compute_global_forwarding_rule" "forwarding_rule_private_service_connect" {
  name                  = "psc${var.name}"
  target                = "all-apis"
  network               = google_compute_network.vpc_network.id
  ip_address            = google_compute_global_address.private_service_connect.id
  load_balancing_scheme = ""
}