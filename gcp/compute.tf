resource "random_password" "token" {
  length  = 16
  special = false
}

resource "google_service_account" "default" {
  account_id   = format("sa-%s", local.name)
  display_name = format("%s Service Account", title(local.name))
}

resource "google_compute_instance" "server" {
  name         = format("vm-%s-server", local.name)
  machine_type = "e2-medium"
  zone         = var.zone

  tags = [
    local.name,
    format("%s-server", local.name)
  ]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-focal-v20210702"
    }
  }

  metadata_startup_script = templatefile("${path.module}/../shared/templates/server.sh", { token = random_password.token.result, interface = "ens4" })

  network_interface {
    network    = google_compute_network.this.self_link
    subnetwork = google_compute_subnetwork.this.self_link

    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }

}

resource "google_compute_instance_template" "client" {
  name_prefix  = format("vm-%s-client-", local.name)
  machine_type = "e2-medium"

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2004-focal-v20210702"
  }

  network_interface {
    network    = google_compute_network.this.self_link
    subnetwork = google_compute_subnetwork.this.self_link
  }

  service_account {
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }

  tags = [
    local.name,
    format("%s-client", local.name)
  ]

  metadata_startup_script = templatefile(
    "${path.module}/../shared/templates/client.sh",
    {
      server_ip = google_compute_instance.server.network_interface.0.network_ip,
      interface = "ens4"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "client" {
  name               = format("igm-%s-client", local.name)
  base_instance_name = format("vm-%s-client", local.name)
  zone               = var.zone
  target_size        = "3"
  target_pools       = [google_compute_target_pool.client.id]

  version {
    name              = local.name
    instance_template = google_compute_instance_template.client.id
  }
}