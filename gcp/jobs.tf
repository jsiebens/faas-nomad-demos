locals {
  nomad_addr = "http://${google_compute_instance.server.network_interface.0.access_config.0.nat_ip}:4646"
}

provider "nomad" {
  address = local.nomad_addr
}

resource "null_resource" "nomad_readiness" {
  triggers = {
    address = local.nomad_addr
  }

  provisioner "local-exec" {
    command = "while ! nomad server members > /dev/null 2>&1; do echo 'waiting for nomad api...'; sleep 10; done"
    environment = {
      NOMAD_ADDR = local.nomad_addr
    }
  }
}

resource "nomad_job" "nats" {
  depends_on = [null_resource.nomad_readiness]
  jobspec = file(
    "${path.module}/../shared/jobs/faas-nats.hcl"
  )
}

resource "nomad_job" "monitoring" {
  depends_on = [null_resource.nomad_readiness]
  jobspec = file(
    "${path.module}/../shared/jobs/faas-monitoring.hcl"
  )
}

resource "nomad_job" "gateway" {
  depends_on = [null_resource.nomad_readiness]
  jobspec = file(
    "${path.module}/../shared/jobs/faas-gateway.hcl"
  )
}