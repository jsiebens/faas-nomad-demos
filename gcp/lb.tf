resource "google_compute_address" "client" {
  name = format("%s-client", local.name)
}

resource "google_compute_forwarding_rule" "client_8080" {
  name       = format("fw-%s-client-8080", local.name)
  region     = var.region
  port_range = 8080
  target     = google_compute_target_pool.client.id
  ip_address = google_compute_address.client.address
}

resource "google_compute_target_pool" "client" {
  name          = format("tp-%s-client", local.name)
  health_checks = [google_compute_http_health_check.gateway.name]
}

resource "google_compute_http_health_check" "gateway" {
  name               = format("hc-%s-gateway", local.name)
  request_path       = "/healthz"
  check_interval_sec = 5
  timeout_sec        = 1
  port               = 8080
}