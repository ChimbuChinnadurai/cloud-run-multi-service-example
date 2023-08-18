resource "google_cloud_run_service" "default" {
  name     = "svc-${var.name}"
  location = "europe-west1"

  metadata {
    annotations = {
      "run.googleapis.com/ingress"              = "internal-and-cloud-load-balancing"
      "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
      "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
    }
  }

  template {
    spec {
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service" "requester" {
  name     = "svc-requester-${var.name}"
  location = "europe-west1"

  template {
    metadata {
      annotations = {
        "run.googleapis.com/ingress"              = "internal-and-cloud-load-balancing"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.self_link
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
      }
    }
    spec {
      containers {
        image   = "nginx"
        command = ["sh", "-c", "echo ${base64encode(templatefile("${path.module}/nginx.conf.tftpl", {service_url = google_cloud_run_service.default.status[0].url }))} | base64 -d > /etc/nginx/conf.d/default.conf && /usr/sbin/nginx -g 'daemon off;'"]
        startup_probe {
          initial_delay_seconds = 0
          timeout_seconds       = 1
          period_seconds        = 3
          failure_threshold     = 1
          tcp_socket {
            port = 80
          }
        }
      }

    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  lifecycle {
    ignore_changes = [template[0].metadata[0].annotations]
  }
}