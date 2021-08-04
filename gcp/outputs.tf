output "summary" {
  value = <<CONFIGURATION

The Nomad UI can be accessed at http://${google_compute_instance.server.network_interface.0.access_config.0.nat_ip}:4646/ui
The Consul UI can be accessed at http://${google_compute_instance.server.network_interface.0.access_config.0.nat_ip}:8500/ui
The Vault UI can be accessed at http://${google_compute_instance.server.network_interface.0.access_config.0.nat_ip}:8200/ui
The OpenFaaS UI can be accessed at http://${google_compute_address.client.address}:8080/ui

CLI environment variables:

export CONSUL_HTTP_ADDR=http://${google_compute_instance.server.network_interface.0.access_config.0.nat_ip}:8500
export NOMAD_ADDR=http://${google_compute_instance.server.network_interface.0.access_config.0.nat_ip}:4646
export VAULT_ADDR=http://${google_compute_instance.server.network_interface.0.access_config.0.nat_ip}:8200
export OPENFAAS_URL=http://${google_compute_address.client.address}:8080
export VAULT_TOKEN=$(gcloud beta compute ssh --zone ${var.zone} ${google_compute_instance.server.name} --project ${var.project} --tunnel-through-iap --command "grep Initial /etc/vault.d/vault-keys.log | cut -c21-")

Authenticate with faas-cli:

vault kv get -field=value openfaas/basic-auth-password | faas-cli login -u admin --password-stdin

CONFIGURATION
}