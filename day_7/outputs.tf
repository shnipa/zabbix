output "prometheus" {
  value = "http://${google_compute_instance.prometheus.network_interface.0.access_config.0.nat_ip}:9090"
}

output "grafana" {
  value = "http://${google_compute_instance.prometheus.network_interface.0.access_config.0.nat_ip}:3000"
}

output "node-exporter" {
  value = "http://${google_compute_instance.prometheus.network_interface.0.access_config.0.nat_ip}:9100"
}

output "alertmanager" {
  value = "http://${google_compute_instance.prometheus.network_interface.0.access_config.0.nat_ip}:9093"
}

output "blackbox" {
  value = "http://${google_compute_instance.prometheus.network_interface.0.access_config.0.nat_ip}:9115"
}

output "node-client" {
  value = "http://${google_compute_instance.node.network_interface.0.access_config.0.nat_ip}:9100"
}