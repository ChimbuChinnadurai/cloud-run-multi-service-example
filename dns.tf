resource "google_dns_managed_zone" "private-zone" {
  name        = "private-zone-${var.name}"
  dns_name    = "run.app."
  description = "Private DNS zone"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc_network.id
    }
  }
}

resource "google_dns_record_set" "a" {
  name         = "*.run.app."
  managed_zone = google_dns_managed_zone.private-zone.name
  type         = "A"
  ttl          = 300

  rrdatas = [google_compute_global_address.private_service_connect.address]
}