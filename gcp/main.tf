locals {
  name = random_pet.name.id
}

resource "random_pet" "name" {
}

resource "google_compute_network" "this" {
  name                    = format("vpc-%s", local.name)
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name          = format("sb-%s", local.name)
  ip_cidr_range = var.ip_range
  network       = google_compute_network.this.id
}

resource "google_compute_router" "this" {
  name    = format("cr-%s", local.name)
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  name                               = format("rn-%s", local.name)
  router                             = google_compute_router.this.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

module "my_ip_address" {
  source  = "matti/resource/shell"
  command = "curl https://ipinfo.io/ip"
}

resource "google_compute_firewall" "fwr_allow_iap" {
  name    = format("fwr-%s-iap", local.name)
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_firewall" "fwr_allow_server" {
  name    = format("fwr-%s-server", local.name)
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["4646", "8500", "8200"]
  }
  source_ranges = [module.my_ip_address.stdout]
  target_tags   = [format("%s-server", local.name)]
}

resource "google_compute_firewall" "fwr_allow_internal" {
  name    = format("fwr-%s-internal", local.name)
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  source_tags = [local.name]
  target_tags = [local.name]
}

resource "google_compute_firewall" "allow_client_ingress" {
  name    = format("fwr-%s-ingress", local.name)
  network = google_compute_network.this.name

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [format("%s-client", local.name)]

  allow {
    protocol = "tcp"
    ports = [
      "8080",
    ]
  }
}